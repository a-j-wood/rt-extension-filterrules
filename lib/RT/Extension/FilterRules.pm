use strict;
use warnings;

package RT::Extension::FilterRules;

our $VERSION = '0.01';

=head1 NAME

RT::Extension::FilterRules - Filter incoming tickets through rule sets

=head1 DESCRIPTION

This extension provides a way for non-technical users to set up ticket
filtering rules which perform actions on tickets when they arrive in a
queue.

Filter rules are grouped into filter rule groups.  The RT administrator
defines the criteria a ticket must meet to be processed by each filter rule
group, and defines which RT groups can manage the filter rules in each rule
group.

For each applicable filter rule group, the rules are checked in order, and
any actions for matching rules are performed on the ticket.  If a matching
rule says that processing must then stop, processing of the rules in that
filter rule group will end, and the next rule group will then be considered.

Filter rules are managed under I<Tools> - I<Filter rules>.

=head1 RT VERSION

Known to work with RT 4.2.16, 4.4.4, and 5.0.1.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions.

=item Set up the database

After running C<make install> for the first time, you will need to create
the database tables for this extension.  Use C<etc/schema-mysql.sql> for
MySQL or MariaDB, or C<etc/schema-postgresql.sql> for PostgreSQL.

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::FilterRules');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your web server

=item Add the processing scrip

Create a new global scrip under I<Admin> - I<Global> - I<Scrips>:

=over 14

=item Description:

Filter rule processing

=item Condition:

On Transaction

=item Action:

User Defined

=item Template:

Blank

=item Stage:

Normal

=item Custom condition:

 return 0 if (not $RT::Extension::FilterRules::VERSION);
 return RT::Extension::FilterRules->ScripIsApplicable($self);

=item Custom action preparation code:

 return 0 if (not $RT::Extension::FilterRules::VERSION);
 return RT::Extension::FilterRules->ScripPrepare($self);

=item Custom action commit code:

 return 0 if (not $RT::Extension::FilterRules::VERSION);
 return RT::Extension::FilterRules->ScripCommit($self);

=back

No filter rules will actually perform any actions until this scrip is
created and enabled.

Note that the C<return 0> lines are only there to prevent errors if you
later remove this extension without disabling the scrip.

=item Set up some filter rule groups

Rule groups are set up by the RT administrator under I<Admin> - I<Tools> -
I<Filter rule groups>.

From that page, the RT administrator can also automatically create the
general processing scrip which runs tickets through the filter rules.
B<Make sure this scrip is created>, otherwise none of the filter rules will
actually do anything.

=back

=head1 TUTORIAL

=head2 Setting up filter rule groups

(TODO)

=head2 Creating filter rules

(TODO)

=head1 AUTHOR

Andrew Wood

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-FilterRules@rt.cpan.org">bug-RT-Extension-FilterRules@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-FilterRules">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-FilterRules@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-FilterRules

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Andrew Wood

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

=head1 INTERNAL FUNCTIONS

These functions are used internally by this extension.  They should all be
called as methods, like this:

 return RT::Extension::FilterRules->ScripIsApplicable($self);

=head2 ScripIsApplicable $Condition

The "is-applicable" condition of the scrip which applies filter rules to
tickets.  Returns true if it is appropriate for this extension to
investigate the action associated with this scrip.

=cut

sub ScripIsApplicable {
    my ( $Package, $Condition ) = @_;

    # The scrip should run on ticket creation.
    #
    return 1 if ( $Condition->TransactionObj->Type eq 'Create' );

    # The scrip should run when a ticket changes queue.
    #
    return 1
        if ( ( $Condition->TransactionObj->Type eq 'Set' )
        && ( $Condition->TransactionObj->Field eq 'Queue' ) );

    # The script should not run otherwise.
    #
    return 0;
}

=head2 ScripPrepare $Action

The "prepare" action of the scrip which applies filter rules to tickets. 
Returns true on success.

=cut

sub ScripPrepare {
    my ( $Package, $Action ) = @_;

    # There are no preparations to make.
    #
    return 1;
}

=head2 ScripCommit $Action

The "commit" action of the scrip which applies filter rules to tickets. 
Returns true on success.

=cut

sub ScripCommit {
    my ( $Package, $Action ) = @_;
    my ( $TriggerType, $QueueFrom, $QueueTo ) = ( undef, undef, undef );
    my ( $FilterRuleGroups, $FilterRuleGroup, $Matches, $Actions );

    #
    # Determine the type of trigger to look for, and the queue(s) involved.
    #
    if ( $Action->TransactionObj->Type eq 'Create' ) {
        $TriggerType = 'Create';
        $QueueFrom   = $Action->TicketObj->Queue;
        $QueueTo     = $QueueFrom;
    } elsif ( ( $Action->TransactionObj->Type eq 'Set' )
        && ( $Action->TransactionObj->Field eq 'Queue' ) )
    {
        $TriggerType = 'QueueMove';
        $QueueFrom   = $Action->TransactionObj->OldValue;
        $QueueTo     = $Action->TransactionObj->NewValue;
    }

    # Nothing to do if we did not determine a trigger type.
    #
    return 0 if ( not defined $TriggerType );

    $Matches = [];
    $Actions = [];

    # Load all filter rule groups.
    #
    $FilterRuleGroups = RT::FilterRuleGroups->new( RT->SystemUser );
    $FilterRuleGroups->Limit(
        'FIELD'    => 'Disabled',
        'VALUE'    => 0,
        'OPERATOR' => '='
    );

    # Check the filter rules in each filter rule group whose group
    # conditions are met, building up a list of actions to perform.
    #
    while ( $FilterRuleGroup = $FilterRuleGroups->Next ) {
        next
            if (
            not $FilterRuleGroup->CheckGroupConditions(
                'Matches'         => [],
                'TriggerType'     => $TriggerType,
                'From'            => $QueueFrom,
                'To'              => $QueueTo,
                'Ticket'          => $Action->TicketObj,
                'IncludeDisabled' => 0
            )
            );
        $FilterRuleGroup->CheckFilterRules(
            'Matches'         => $Matches,
            'Actions'         => $Actions,
            'From'            => $QueueFrom,
            'To'              => $QueueTo,
            'Ticket'          => $Action->TicketObj,
            'IncludeDisabled' => 0
        );
    }

    # Perform the actions we have accumulated.
    #
    foreach (@$Actions) {
        $Package->PerformAction(
            'Action' => $_,
            'Ticket' => $Action->TicketObj
        );
    }

    return 1;
}

=head2 PerformAction Action => ACTION, Ticket => TICKET

Perform the given action on the given ticket.

(TODO)

=cut

sub PerformAction {
    my $Package = shift;
    my %args    = (
        'Action' => undef,
        'Ticket' => 0,
        @_
    );

    # TODO: writeme

    return (1, '');
}

{

=head1 Internal package RT::FilterRuleGroup

This package provides the C<RT::FilterRuleGroup> class, which describes a
group of filter rules through which a ticket will be passed if it meets the
basic conditions of the group.

The attributes of this class are:

=over 20

=item id

The numeric ID of this filter rule group

=item SortOrder

The order of processing - filter rule groups with a lower sort order are
processed first

=item Name

The displayed name of this filter rule group

=item CanMatchQueues

The queues which rules in this rule group are allowed to use in their
conditions, as a comma-separated list of queue IDs (also presented as an
C<RT::Queues> object via B<CanMatchQueuesObj>)

=item CanTransferQueues

The queues which rules in this rule group are allowed to use as transfer
destinations in their actions, as a comma-separated list of queue IDs (also
presented as an C<RT::Queues> object via B<CanTransferQueuesObj>)

=item CanUseGroups

The groups which rules in this rule group are allowed to use in match
conditions and actions, as a comma-separated list of group IDs (also
presented as an C<RT::Groups> object via B<CanUseGroupsObj>)

=item Creator

The numeric ID of the creator of this filter rule group (also presented as
an C<RT::User> object via B<CreatorObj>)

=item Created

The date and time this filter rule group was created (also presented as an
C<RT::Date> object via B<CreatedObj>)

=item LastUpdatedBy

The numeric ID of the user who last updated the properties of this filter
rule group (also presented as an C<RT::User> object via B<LastUpdatedByObj>)

=item LastUpdated

The date and time this filter rule group's properties were last updated
(also presented as an C<RT::Date> object via B<LastUpdatedObj>)

=item Disabled

Whether this filter rule group is disabled; the filter rule group is active
unless this property is true

=back

The basic conditions of the filter rule group are defined by its
B<GroupConditions> object, which is a collection of C<RT::FilterRule>
objects whose B<IsGroupCondition> attribute is true.  If any of these rules
match, the ticket is eligible to be passed through the rules for this group.

The filter rules for this group presented via B<FilterRules>, which is a
collection of C<RT::FilterRule> objects.

Filter rule groups themselves can only be created, modified, and deleted by
users with the I<SuperUser> right.

The following rights can be assigned to individual filter rule groups to
delegate control of the filter rules within them:

=over

=item SeeFilterRule

View the filter rules in this filter rule group

=item ModifyFilterRule

Modify existing filter rules in this filter rule group

=item CreateFilterRule

Create new filter rules in this filter rule group

=item DeleteFilterRule

Delete filter rules from this filter rule group

=back

These are assigned using the rights pages of the filter rule group, under
I<Admin> - I<Tools> - I<Filter rule groups>.

=cut

    package RT::FilterRuleGroup;
    use base 'RT::Record';

    use Role::Basic 'with';
    with 'RT::Record::Role::Rights';

    sub Table {'FilterRuleGroups'}

    __PACKAGE__->AddRight(
        'Staff' => 'SeeFilterRule' => 'View filter rules' );    # loc
    __PACKAGE__->AddRight(
        'Staff' => 'ModifyFilterRule' => 'Modify filter rules' );    # loc
    __PACKAGE__->AddRight(
        'Staff' => 'CreateFilterRule' => 'Create new filter rules' );    # loc
    __PACKAGE__->AddRight(
        'Staff' => 'DeleteFilterRule' => 'Delete filter rules' );        # loc

    use RT::Transactions;

=head1 RT::FilterRuleGroup METHODS

Note that additional methods will be available, inherited from
C<RT::Record>.

=cut

=head2 Create Name => Name, ...

Create a new filter rule group with the supplied properties, as described
above.  The sort order will be set to 1 more than the highest current value
so that the new item appears at the end of the list.

Returns ( I<$id>, I<$message> ), where I<$id> is the ID of the new object,
which will be undefined if there was a problem.

=cut

    sub Create {
        my $self = shift;
        my %args = (
            'Name'              => '',
            'CanMatchQueues'    => '',
            'CanTransferQueues' => '',
            'CanUseGroups'      => '',
            'Disabled'          => 0,
            @_
        );

        # Allow the fields which take ID lists to be passed as arrayrefs of
        # IDs, arrayrefs of RT::Queue or RT::Group objects, or as RT::Queues
        # or RT::Groups collection objects, by converting all of those back
        # to a comma separated list of IDs.
        #
        foreach my $Field ( 'CanMatchQueues', 'CanTransferQueues',
            'CanUseGroups' )
        {
            my $Value = $args{$Field};

            # Convert a collection object into an array ref
            #
            if (   ( ref $Value )
                && ( ref $Value ne 'ARRAY' )
                && (   UNIVERSAL::isa( $Value, 'RT::Queues' )
                    || UNIVERSAL::isa( $Value, 'RT::Groups' ) )
               )
            {
                $Value = $Value->ItemsArrayRef();
            }

            # Convert an array ref into a comma separated ID list
            #
            if ( ref $Value eq 'ARRAY' ) {
                $Value = join( ',',
                    map { ref $Value ? $Value->id : $Value } @$Value );
            }

            $args{$Field} = $Value;
        }

        $args{'SortOrder'} = 1;

        $RT::Handle->BeginTransaction();

        my $AllFilterRuleGroups
            = RT::FilterRuleGroups->new( $self->CurrentUser );
        $AllFilterRuleGroups->OrderByCols(
            { FIELD => 'SortOrder', ORDER => 'DESC' } );
        $AllFilterRuleGroups->GotoFirstItem();
        my $FinalFilterRuleGroup = $AllFilterRuleGroups->Next;
        $args{'SortOrder'} = 1 + $FinalFilterRuleGroup->SortOrder
            if ($FinalFilterRuleGroup);

        my ( $id, $msg ) = $self->SUPER::Create(%args);
        unless ($id) {
            $RT::Handle->Rollback();
            return ( undef, $msg );
        }

        my ( $txn_id, $txn_msg, $txn )
            = $self->_NewTransaction( Type => 'Create' );
        unless ($txn_id) {
            $RT::Handle->Rollback();
            return ( undef, $self->loc( 'Internal error: [_1]', $txn_msg ) );
        }
        $RT::Handle->Commit();

        return ( $id,
            $self->loc( 'Filter rule group [_1] created', $self->id ) );
    }

=head2 CanMatchQueues

Return the queues which rules in this rule group are allowed to use in their
conditions, as a comma-separated list of queue IDs in a scalar context, or
as an array of queue IDs in a list context.

=cut

    sub CanMatchQueues {
        my ($self) = @_;
        my $Value = $self->_Value('CanMatchQueues');
        return wantarray ? split /,/, $Value : $Value;
    }

=head2 CanMatchQueuesObj

Return the same as B<CanMatchQueues>, but as an C<RT::Queues> object, i.e. a
collection of C<RT::Queue> objects.

=cut

    sub CanMatchQueuesObj {
        my ($self) = @_;
        my ( @Values, $Collection );
        @Values     = $self->CanMatchQueues;
        $Collection = RT::Queues->new( $self->CurrentUser );
        $Collection->Limit(
            'FIELD'           => 'id',
            'VALUE'           => $_,
            'OPERATOR'        => '=',
            'ENTRYAGGREGATOR' => 'OR'
        ) foreach (@Values);
        $Collection->Limit(
            'FIELD'    => 'id',
            'VALUE'    => 0,
            'OPERATOR' => '='
        ) if ( scalar @Values < 1 );
        return $Collection;
    }

=head2 CanTransferQueues

Return the queues which rules in this rule group are allowed to use as
transfer destinations in their actions, as a comma-separated list of queue
IDs in a scalar context, or as an array of queue IDs in a list context.

=cut

    sub CanTransferQueues {
        my ($self) = @_;
        my $Value = $self->_Value('CanTransferQueues');
        return wantarray ? split /,/, $Value : $Value;
    }

=head2 CanTransferQueuesObj

Return the same as B<CanTransferQueues>, but as an C<RT::Queues> object,
i.e. a collection of C<RT::Queue> objects.

=cut

    sub CanTransferQueuesObj {
        my ($self) = @_;
        my ( @Values, $Collection );
        @Values     = $self->CanTransferQueues;
        $Collection = RT::Queues->new( $self->CurrentUser );
        $Collection->Limit(
            'FIELD'           => 'id',
            'VALUE'           => $_,
            'OPERATOR'        => '=',
            'ENTRYAGGREGATOR' => 'OR'
        ) foreach (@Values);
        $Collection->Limit(
            'FIELD'    => 'id',
            'VALUE'    => 0,
            'OPERATOR' => '='
        ) if ( scalar @Values < 1 );
        return $Collection;
    }

=head2 CanUseGroups

Return the groups which rules in this rule group are allowed to use in match
conditions and actions, as a comma-separated list of group IDs in a scalar
context, or as an array of group IDs in a list context.

=cut

    sub CanUseGroups {
        my ($self) = @_;
        my $Value = $self->_Value('CanUseGroups');
        return wantarray ? split /,/, $Value : $Value;
    }

=head2 CanUseGroupsObj

Return the same as B<CanUseGroups>, but as an C<RT::Groups> object, i.e. a
collection of C<RT::Group> objects.

=cut

    sub CanUseGroupsObj {
        my ($self) = @_;
        my ( @Values, $Collection );
        @Values     = $self->CanUseGroups;
        $Collection = RT::Groups->new( $self->CurrentUser );
        $Collection->Limit(
            'FIELD'           => 'id',
            'VALUE'           => $_,
            'OPERATOR'        => '=',
            'ENTRYAGGREGATOR' => 'OR'
        ) foreach (@Values);
        $Collection->Limit(
            'FIELD'    => 'id',
            'VALUE'    => 0,
            'OPERATOR' => '='
        ) if ( scalar @Values < 1 );
        return $Collection;
    }

=head2 SetCanMatchQueues id, id, ...

Set the queues which rules in this rule group are allowed to use in their
conditions, either as a comma-separated list of queue IDs, an array of queue
IDs, an array of C<RT::Queue> objects, or an C<RT::Queues> collection.

Returns ( I<$ok>, I<$message> ).

=cut

    sub SetCanMatchQueues {
        my ( $self, @NewValues ) = @_;
        my %NewIDs = ();

        foreach my $Item (@NewValues) {
            if ( not ref $Item ) {
                foreach ( split /,/, $Item ) {
                    next if ( !/([0-9]+)/ );
                    $NewIDs{$1} = 1;
                }
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Queue' ) ) {
                $NewIDs{ $Item->id } = 1 if ( $Item->id );
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Queues' ) ) {
                $Item->GotoFirstItem();
                while ( my $Object = $Item->Next() ) {
                    $NewIDs{ $Object->id } = 1 if ( $Object->id );
                }
            }
        }

        return $self->_Set(
            'Field' => 'CanMatchQueues',
            'Value' => join( ',', sort { $a <=> $b } keys %NewIDs )
        );
    }

=head2 SetCanTransferQueues id, id, ...

Set the queues which rules in this filter rule group are allowed to use as
transfer destinations in their actions, either as a comma-separated list of
queue IDs, an array of queue IDs, an array of C<RT::Queue> objects, or an
C<RT::Queues> collection.

Returns ( I<$ok>, I<$message> ).

=cut

    sub SetCanTransferQueues {
        my ( $self, @NewValues ) = @_;
        my %NewIDs = ();

        foreach my $Item (@NewValues) {
            if ( not ref $Item ) {
                foreach ( split /,/, $Item ) {
                    next if ( !/([0-9]+)/ );
                    $NewIDs{$1} = 1;
                }
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Queue' ) ) {
                $NewIDs{ $Item->id } = 1 if ( $Item->id );
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Queues' ) ) {
                $Item->GotoFirstItem();
                while ( my $Object = $Item->Next() ) {
                    $NewIDs{ $Object->id } = 1 if ( $Object->id );
                }
            }
        }

        return $self->_Set(
            'Field' => 'CanTransferQueues',
            'Value' => join( ',', sort { $a <=> $b } keys %NewIDs )
        );
    }

=head2 SetCanUseGroups id, id, ...

Set the groups which rules in this rule group are allowed to use in match
conditions and actions, either as a comma-separated list of group IDs, an
array of group IDs, an array of C<RT::Group> objects, or an C<RT::Groups>
collection.

Returns ( I<$ok>, I<$message> ).

=cut

    sub SetCanUseGroups {
        my ( $self, @NewValues ) = @_;
        my %NewIDs = ();

        foreach my $Item (@NewValues) {
            if ( not ref $Item ) {
                foreach ( split /,/, $Item ) {
                    next if ( !/([0-9]+)/ );
                    $NewIDs{$1} = 1;
                }
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Group' ) ) {
                $NewIDs{ $Item->id } = 1 if ( $Item->id );
            } elsif ( UNIVERSAL::isa( $Item, 'RT::Groups' ) ) {
                $Item->GotoFirstItem();
                while ( my $Object = $Item->Next() ) {
                    $NewIDs{ $Object->id } = 1 if ( $Object->id );
                }
            }
        }

        return $self->_Set(
            'Field' => 'CanUseGroups',
            'Value' => join( ',', sort { $a <=> $b } keys %NewIDs )
        );
    }

=head2 GroupConditions

Return an C<RT::FilterRules> collection object containing the conditions of
this filter rule group - if an event meets any of these conditions, then the
caller should process the event through the B<FilterRules> for this group.

=cut

    sub GroupConditions {
        my ($self) = @_;

        my $Collection = RT::FilterRules->new( $self->CurrentUser );
        $Collection->Limit(
            'FIELD'    => 'FilterRuleGroup',
            'VALUE'    => $self->id,
            'OPERATOR' => '='
        );
        $Collection->Limit(
            'FIELD'    => 'IsGroupCondition',
            'VALUE'    => 1,
            'OPERATOR' => '='
        );

        return $Collection;
    }

=head2 AddGroupCondition Name => NAME, ...

Add a condition to this filter rule group; calls B<RT::FilterRule::Create>
below, overriding the B<FilterRuleGroup> parameter, and returns its output.

=cut

    sub AddGroupCondition {
        my $self = shift;
        my %args = (@_);

        return RT::FilterRule->new(
            $self->CurrentUser, %args,
            'FilterRuleGroup'  => $self->id,
            'IsGroupCondition' => 1
        );
    }

=head2 FilterRules

Return an C<RT::FilterRules> collection object containing the filter rules
for this rule group.

=cut

    sub FilterRules {
        my ($self) = @_;

        my $Collection = RT::FilterRules->new( $self->CurrentUser );
        $Collection->Limit(
            'FIELD'    => 'FilterRuleGroup',
            'VALUE'    => $self->id,
            'OPERATOR' => '='
        );
        $Collection->Limit(
            'FIELD'    => 'IsGroupCondition',
            'VALUE'    => 0,
            'OPERATOR' => '='
        );

        return $Collection;
    }

=head2 AddFilterRule Name => NAME, ...

Add a filter rule to this filter rule group; calls B<RT::FilterRule::Create>
below, overriding the B<FilterRuleGroup> parameter, and returns its output.

=cut

    sub AddFilterRule {
        my $self = shift;
        my %args = (@_);

        return RT::FilterRule->new(
            $self->CurrentUser, %args,
            'FilterRuleGroup'  => $self->id,
            'IsGroupCondition' => 0
        );
    }

=head2 SetDisabled BOOLEAN

Mark this filter rule group as disabled if I<BOOLEAN> is true, or active if
false.  Disabled filter rule groups are not considered when filtering
events.

=cut

sub SetDisabled {
    my $self = shift;
    my $val  = shift;

    return ( 1, $self->loc('No change made') )
        if ( ( $self->Disabled && $val )
        || ( ( not $val ) && ( not $self->Disabled ) ) );

    $RT::Handle->BeginTransaction();
    my ( $ok, $msg )
        = $self->_Set( 'Field' => 'Disabled', 'Value' => $val ? 1 : 0 );
    unless ($ok) {
        $RT::Handle->Rollback();
        return ( $ok, $msg );
    }
    $self->_NewTransaction( Type => ( $val == 0 ) ? 'Enabled' : 'Disabled' );

    $RT::Handle->Commit();

    if ( $val == 0 ) {
        return ( 1, $self->loc('Filter rule group enabled') );
    } else {
        return ( 1, $self->loc('Filter rule group disabled') );
    }
}

=head2 Delete

Delete this filter rule group, and all of its filter rules.  Returns
( I<$ok>, I<$message> ).

=cut

    sub Delete {
        my ($self) = @_;
        my ( $Collection, $Item );

        # Delete the group conditions.
        #
        $Collection = $self->GroupConditions();
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            $Item->Delete();
        }

        # Delete the filter rules.
        #
        $Collection = $self->FilterRules();
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            $Item->Delete();
        }

        # Delete the transactions.
        #
        $Collection = $self->Transactions();
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            $Item->Delete();
        }

        # Delete this object itself.
        #
        return $self->SUPER::Delete();
    }

=head2 CheckGroupConditions Matches => [], TriggerType => ...,

For the given event, append details of matching group conditions to the
I<Matches> array reference.

A I<Ticket> should be supplied, either as an ID or as an C<RT::Ticket> object.

Returns true if there were any matches (meaning that the caller should pass
the event through this filter rule group's B<FilterRules>), false if there
were no matches.

If I<IncludeDisabled> is true, then even rules marked as disabled will be
checked.  The default is false.

See B<RT::FilterRule::Match> for the structure of the I<Matches> array
entries, and the event structure.

=cut

    sub CheckGroupConditions {
        my $self = shift;
        my %args = (
            'Matches'     => [],
            'TriggerType' => '',
            'From'        => 0,
            'To'          => 0,
            'Ticket'      => 0,
            'IncludeDisabled' => 0,
            @_
        );
        my ( $Collection, $Item );

        $Collection = $self->GroupConditions();
        $Collection->Limit('FIELD' => 'Disabled', 'VALUE' => 0, 'OPERATOR' => '=') if (not $args{'IncludeDisabled'});
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            return 1
                if (
                $Item->Match(
                    'Matches'     => $args{'Matches'},
                    'Actions'     => [],
                    'TriggerType' => $args{'TriggerType'},
                    'From'        => $args{'From'},
                    'To'          => $args{'To'},
                    'Ticket'      => $args{'Ticket'}
                )
                );
        }

        return 0;
    }

=head2 CheckFilterRules Matches => [], Actions => [], TriggerType => ...,

For the given event, append details of matching filter rules to the
I<Matches> array reference, and append details of the actions which should
be performed due to those matches to the I<Actions> array reference.

A I<Ticket> should be supplied, either as an ID or as an C<RT::Ticket> object.

If I<IncludeDisabled> is true, then even rules marked as disabled will be
checked.  The default is false.

If I<RecordMatch> is true, then the fact that a rule is matched will be
recorded in the database (see C<RT::FilterRuleMatch>).  The default is not
to record the match.

Returns true if there were any matches, false otherwise.

See B<RT::FilterRule::Match> for the structure of the I<Matches> and
I<Actions> array entries, and the event structure.

=cut

    sub CheckFilterRules {
        my $self = shift;
        my %args = (
            'Matches'     => [],
            'Actions'     => [],
            'TriggerType' => '',
            'From'        => 0,
            'To'          => 0,
            'Ticket'      => 0,
            'IncludeDisabled' => 0,
            'RecordMatch' => 0,
            @_
        );
        my ( $Collection, $Item, $MatchesFound );

        $MatchesFound = 0;

        $Collection = $self->FilterRules();
        $Collection->Limit('FIELD' => 'Disabled', 'VALUE' => 0, 'OPERATOR' => '=') if (not $args{'IncludeDisabled'});
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            if ($Item->Match(
                    'Matches'     => $args{'Matches'},
                    'Actions'     => $args{'Actions'},
                    'TriggerType' => $args{'TriggerType'},
                    'From'        => $args{'From'},
                    'To'          => $args{'To'},
                    'Ticket'      => $args{'Ticket'}
                )
               )
            {
                $MatchesFound = 1;
                $Item->RecordMatch('Ticket' => $args{'Ticket'})
                if ($args{'RecordMatch'});
                return 1 if ( $Item->StopIfMatched );
            }
        }

        return $MatchesFound;
    }

=head2 _Set Field => FIELD, Value => VALUE

Set the value of a field, recording a transaction in the process if
appropriate.  Returns ( I<$ok>, I<$message> ).

=cut

    sub _Set {
        my $self = shift;
        my %args = (
            'Field' => '',
            'Value' => '',
            @_
        );

        my $OldValue = $self->__Value( $args{'Field'} );
        return ( 1, $self->loc('No change made') )
            if ( ( defined $OldValue )
            && ( defined $args{'Value'} )
            && ( $OldValue eq $args{'Value'} ) );

        $RT::Handle->BeginTransaction();

        my ( $ok, $msg ) = $self->SUPER::_Set(%args);

        if ( not $ok ) {
            $RT::Handle->Rollback();
            return ( $ok, $msg );
        }

        # Don't record a transaction for sort order changes, since they are
        # very frequent.
        #
        if ( ( $args{'Field'} || '' ) ne 'SortOrder' ) {
            my ( $txn_id, $txn_msg, $txn ) = $self->_NewTransaction(
                'Type'     => 'Set',
                'Field'    => $args{'Field'},
                'NewValue' => $args{'Value'},
                'OldValue' => $OldValue
            );
            if ( not $txn_id ) {
                $RT::Handle->Rollback();
                return ( 0, $self->loc( 'Internal error: [_1]', $txn_msg ) );
            }
        }

        $RT::Handle->Commit();

        return ( $ok, $msg );
    }

=head2 _CoreAccessible

Return a hashref describing the attributes of the database table for the
C<RT::FilterRuleGroup> class.

=cut

    sub _CoreAccessible {
        return {

            'id' => {
                read       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => ''
            },

            'SortOrder' => {
                read       => 1,
                write      => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Name' => {
                read       => 1,
                write      => 1,
                sql_type   => 12,
                length     => 200,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'varchar(200)',
                default    => ''
            },

            'CanMatchQueues' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'CanTransferQueues' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'CanUseGroups' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'Creator' => {
                read       => 1,
                auto       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Created' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            },

            'LastUpdatedBy' => {
                read       => 1,
                auto       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'LastUpdated' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            },

            'Disabled' => {
                read       => 1,
                write      => 1,
                sql_type   => 5,
                length     => 6,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'smallint(6)',
                default    => '0'
            }
        };
    }

    RT::Base->_ImportOverlays();
}

{

=head1 Internal package RT::FilterRuleGroups

This package provides the C<RT::FilterRuleGroups> class, which describes a
collection of filter rule groups.

=cut

    package RT::FilterRuleGroups;

    use base 'RT::SearchBuilder';

    sub Table {'FilterRuleGroups'}

    sub _Init {
        my $self = shift;
        $self->OrderByCols(
            { FIELD => 'SortOrder', ORDER => 'ASC' },
            { FIELD => 'Name',      ORDER => 'ASC' },
        );
        return $self->SUPER::_Init(@_);
    }

    RT::Base->_ImportOverlays();
}

{

=head1 Internal package RT::FilterRule

This package provides the C<RT::FilterRule> class, which describes a filter
rule - the conditions it must not meet, the conditions it must meet, and the
actions to perform on the ticket if the rule matches.

The attributes of this class are:

=over 20

=item id

The numeric ID of this filter rule

=item FilterRuleGroup

The numeric ID of the filter rule group to which this filter rule belongs
(also presented as an C<RT::FilterRuleGroup> object via
B<FilterRuleGroupObj>)

=item IsGroupCondition

Whether this is a filter rule which describes conditions under which the
filter rule group as a whole is applicable (true), or a filter rule for
processing an event through and performing actions if matched (false).

This is true for filter rules under a rule group's B<GroupConditions>, and
false for filter rules under a rule group's B<FilterRules>.

This attribute is set automatically when a C<RT::FilterRule> object is
created via the B<AddGroupCondition> and B<AddFilterRule> methods of
C<RT::FilterRuleGroup>.

=item SortOrder

The order of processing - filter rules with a lower sort order are processed
first

=item Name

The displayed name of this filter rule

=item TriggerType

The type of action which triggers this filter rule - one of:

=over 10

=item Create

Consider this rule on ticket creation

=item QueueMove

Consider this rule when the ticket moves between queues

=back

=item StopIfMatched

If this is true, then processing of the remaining rules in this filter rule
group should be skipped if this rule matches

=item Conflicts

Conditions which, if met, mean this rule cannot match (TODO: define format)

=item Requirements

Conditions which, if any are met, mean this rule matches, so long as none of
the conflict conditions above have matched (TODO: define format)

=item Actions

Actions to carry out on the ticket if the rule matches; this field is unused
for filter rule group applicability rules (where B<IsGroupCondition> is 1)
(TODO: define format)

=item Creator

The numeric ID of the creator of this filter rule (also presented as an
C<RT::User> object via B<CreatorObj>)

=item Created

The date and time this filter rule was created (also presented as an
C<RT::Date> object via B<CreatedObj>)

=item LastUpdatedBy

The numeric ID of the user who last updated the properties of this filter
rule (also presented as an C<RT::User> object via B<LastUpdatedByObj>)

=item LastUpdated

The date and time this filter rule's properties were last updated (also
presented as an C<RT::Date> object via B<LastUpdatedObj>)

=item Disabled

Whether this filter rule is disabled; the filter rule is active unless this
property is true

=back

=cut

    package RT::FilterRule;
    use base 'RT::Record';

    sub Table {'FilterRules'}

    use RT::Transactions;

=head1 RT::FilterRule METHODS

Note that additional methods will be available, inherited from
C<RT::Record>.

=cut

=head2 Create Name => Name, ...

Create a new filter rule with the supplied properties, as described above. 
The sort order will be set to 1 more than the highest current value so that
the new item appears at the end of the list.

Returns ( I<$id>, I<$message> ), where I<$id> is the ID of the new object,
which will be undefined if there was a problem.

=cut

    sub Create {
        my $self = shift;
        my %args = (
            'FilterRuleGroup'  => 0,
            'IsGroupCondition' => 0,
            'Name'             => '',
            'TriggerType'      => '',
            'StopIfMatched'    => 0,
            'Conflicts'        => '',
            'Requirements'     => '',
            'Actions'          => '',
            'Disabled'         => 0,
            @_
        );

        # Convert FilterRuleGroup to an ID if an object was passed.
        #
        $args{'FilterRuleGroup'} = $args{'FilterRuleGroup'}->id
            if ( ( ref $args{'FilterRuleGroup'} )
            && UNIVERSAL::isa( $args{'FilterRuleGroup'}, 'RT::FilterRuleGroup' ) );

        # TODO: parse Conflicts, Requirements, Actions

        # Normalise IsGroupCondition to 1 or 0
        $args{'IsGroupCondition'} = $args{'IsGroupCondition'} ? 1 : 0;

        $args{'SortOrder'} = 1;

        $RT::Handle->BeginTransaction();

        my $AllFilterRules = RT::FilterRules->new( $self->CurrentUser );

        $AllFilterRules->Limit(
            'FIELD'    => 'FilterRuleGroup',
            'VALUE'    => $args{'FilterRuleGroup'},
            'OPERATOR' => '='
        );
        $AllFilterRules->Limit(
            'FIELD'    => 'IsGroupCondition',
            'VALUE'    => $args{'IsGroupCondition'},
            'OPERATOR' => '='
        );
        $AllFilterRules->OrderByCols(
            { FIELD => 'SortOrder', ORDER => 'DESC' } );
        $AllFilterRules->GotoFirstItem();
        my $FinalFilterRule = $AllFilterRules->Next;
        $args{'SortOrder'} = 1 + $FinalFilterRule->SortOrder
            if ($FinalFilterRule);

        my ( $id, $msg ) = $self->SUPER::Create(%args);
        unless ($id) {
            $RT::Handle->Rollback();
            return ( undef, $msg );
        }

        my ( $txn_id, $txn_msg, $txn )
            = $self->_NewTransaction( Type => 'Create' );
        unless ($txn_id) {
            $RT::Handle->Rollback();
            return ( undef, $self->loc( 'Internal error: [_1]', $txn_msg ) );
        }
        $RT::Handle->Commit();

        return ( $id, $self->loc( 'Filter rule [_1] created', $self->id ) );
    }

=head2 FilterRuleGroupObj

Return an C<RT::FilterRuleGroup> object containing this filter rule's filter
rule group.

=cut

    sub FilterRuleGroupObj {
        my ($self) = @_;

        if (   !$self->{'_FilterRuleGroup_obj'}
            || !$self->{'_FilterRuleGroup_obj'}->id )
        {

            $self->{'_FilterRuleGroup_obj'}
                = RT::FilterRuleGroup->new( $self->CurrentUser );
            my ($result)
                = $self->{'_FilterRuleGroup_obj'}
                ->Load( $self->__Value('FilterRuleGroup') );
        }
        return ( $self->{'_FilterRuleGroup_obj'} );
    }

=head2 SetConflicts VALUE

Set the conditions which, if met, mean this rule cannot match (TODO: define format).

(TODO)

=cut

    sub SetConflicts {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
        return (0, '');
    }

=head2 SetRequirements

Set the conditions which, if any are met, mean this rule matches, so long as
none of the conflict conditions above have matched (TODO: define format).

(TODO)

=cut

    sub SetRequirements {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
        return (0, '');
    }

=head2 SetActions

Set the actions to carry out on the ticket if the rule matches; this field
is unused for filter rule group applicability rules (where
B<IsGroupCondition> is 1) (TODO: define format).

(TODO)

=cut

    sub SetActions {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
        return (0, '');
    }

=head2 SetDisabled BOOLEAN

Mark this filter rule as disabled if I<BOOLEAN> is true, or active if false. 
Disabled filter rules are not considered when filtering events.

=cut

sub SetDisabled {
    my $self = shift;
    my $val  = shift;

    return ( 1, $self->loc('No change made') )
        if ( ( $self->Disabled && $val )
        || ( ( not $val ) && ( not $self->Disabled ) ) );

    $RT::Handle->BeginTransaction();
    my ( $ok, $msg )
        = $self->_Set( 'Field' => 'Disabled', 'Value' => $val ? 1 : 0 );
    unless ($ok) {
        $RT::Handle->Rollback();
        return ( $ok, $msg );
    }
    $self->_NewTransaction( Type => ( $val == 0 ) ? 'Enabled' : 'Disabled' );

    $RT::Handle->Commit();

    if ( $val == 0 ) {
        return ( 1, $self->loc('Filter rule enabled') );
    } else {
        return ( 1, $self->loc('Filter rule disabled') );
    }
}

=head2 Delete

Delete this filter rule, and all of its history.  Returns ( I<$ok>,
I<$message> ).

=cut

    sub Delete {
        my ($self) = @_;
        my ( $Collection, $Item );

        # Delete the filter rule match history.
        #
        $Collection = $self->MatchHistory();
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            $Item->Delete();
        }

        # Delete the transactions.
        #
        $Collection = $self->Transactions();
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            $Item->Delete();
        }

        # Delete this object itself.
        #
        return $self->SUPER::Delete();
    }

=head2 MatchHistory

Return an C<RT::FilterRuleMatches> collection containing all of the times
this filter rule matched an event.

=cut

    sub MatchHistory {
        my ($self) = @_;
        my $Collection = RT::FilterRuleMatches->new( $self->CurrentUser );
        $Collection->Limit(
            'FIELD'    => 'FilterRule',
            'VALUE'    => $self->id,
            'OPERATOR' => '='
        );
        return $Collection;
    }

=head2 Match Matches => [], Actions => [], TriggerType => TYPE, From => FROM, To => TO

Return true if this filter rule matches the given event, false otherwise. 
If returning true, details of this rule and the matching condition will be
appended to the I<Matches> array reference, and the actions this rule
contains will be appended to the I<Actions> array reference.

The I<TriggerType> should be one of the valid I<TriggerType> attribute
values listed above in the C<RT::FilterRule> class attributes documentation.

For a I<TriggerType> of B<Create>, indicating a ticket creation event, the
I<To> parameter should be the ID of the queue the ticket was created in.

For a I<TriggerType> of B<QueueMove>, indicating a ticket moving from one
queue to another, the I<From> parameter should be the ID of the queue the
ticket was in before the move, and the I<To> parameter should be the ID of
the queue the ticket moved into.

(TODO)

=cut

    sub Match {
        my $self = shift;
        my %args = (
            'Matches'     => [],
            'Actions'     => [],
            'TriggerType' => '',
            'From'        => 0,
            'To'          => 0,
            @_
        );

        # TODO: writeme

        return 0;
    }

=head2 RecordMatch Ticket => ID

Record the fact that an event relating to the given ticket matched this
filter rule.

=cut

    sub RecordMatch {
        my $self = shift;
        my %args = ( 'Ticket' => 0, @_ );

        my $MatchObj = RT::FilterRuleMatch->new( $self->CurrentUser );

        return $MatchObj->Create(
            'FilterRule' => $self->id,
            'Ticket'     => $args{'Ticket'}
        );
    }

=head2 _Set Field => FIELD, Value => VALUE

Set the value of a field, recording a transaction in the process if
appropriate.  Returns ( I<$ok>, I<$message> ).

=cut

    sub _Set {
        my $self = shift;
        my %args = (
            'Field' => '',
            'Value' => '',
            @_
        );

        my $OldValue = $self->__Value( $args{'Field'} );
        return ( 1, $self->loc('No change made') )
            if ( ( defined $OldValue )
            && ( defined $args{'Value'} )
            && ( $OldValue eq $args{'Value'} ) );

        $RT::Handle->BeginTransaction();

        my ( $ok, $msg ) = $self->SUPER::_Set(%args);

        if ( not $ok ) {
            $RT::Handle->Rollback();
            return ( $ok, $msg );
        }

        # Don't record a transaction for sort order changes, since they are
        # very frequent.
        #
        # TODO: special "Type" for Conflicts, Requirements, Actions, with
        # matching %RT::Transaction::_BriefDescription entries.
        #
        if ( ( $args{'Field'} || '' ) ne 'SortOrder' ) {
            my ( $txn_id, $txn_msg, $txn ) = $self->_NewTransaction(
                'Type'     => 'Set',
                'Field'    => $args{'Field'},
                'NewValue' => $args{'Value'},
                'OldValue' => $OldValue
            );
            if ( not $txn_id ) {
                $RT::Handle->Rollback();
                return ( 0, $self->loc( 'Internal error: [_1]', $txn_msg ) );
            }
        }

        $RT::Handle->Commit();

        return ( $ok, $msg );
    }

=head2 _CoreAccessible

Return a hashref describing the attributes of the database table for the
C<RT::FilterRule> class.

=cut

    sub _CoreAccessible {
        return {

            'id' => {
                read       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => ''
            },

            'FilterRuleGroup' => {
                read       => 1,
                write      => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'IsGroupCondition' => {
                read       => 1,
                write      => 1,
                sql_type   => 5,
                length     => 6,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'smallint(6)',
                default    => '0'
            },

            'SortOrder' => {
                read       => 1,
                write      => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Name' => {
                read       => 1,
                write      => 1,
                sql_type   => 12,
                length     => 200,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'varchar(200)',
                default    => ''
            },

            'TriggerType' => {
                read       => 1,
                write      => 1,
                sql_type   => 12,
                length     => 200,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'varchar(200)',
                default    => ''
            },

            'StopIfMatched' => {
                read       => 1,
                write      => 1,
                sql_type   => 5,
                length     => 6,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'smallint(6)',
                default    => '0'
            },

            'Conflicts' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'Requirements' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'Actions' => {
                read       => 1,
                write      => 1,
                sql_type   => -4,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'text',
                default    => ''
            },

            'Creator' => {
                read       => 1,
                auto       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Created' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            },

            'LastUpdatedBy' => {
                read       => 1,
                auto       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'LastUpdated' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            },

            'Disabled' => {
                read       => 1,
                write      => 1,
                sql_type   => 5,
                length     => 6,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'smallint(6)',
                default    => '0'
            }
        };
    }

    RT::Base->_ImportOverlays();
}

{

=head1 Internal package RT::FilterRules

This package provides the C<RT::FilterRules> class, which describes a
collection of filter rules.

=cut

    package RT::FilterRules;

    use base 'RT::SearchBuilder';

    sub Table {'FilterRules'}

    sub _Init {
        my $self = shift;
        $self->OrderByCols(
            { FIELD => 'SortOrder', ORDER => 'ASC' },
            { FIELD => 'Name',      ORDER => 'ASC' },
        );
        return $self->SUPER::_Init(@_);
    }

    RT::Base->_ImportOverlays();
}

{

=head1 Internal package RT::FilterRuleMatch

This package provides the C<RT::FilterRuleMatch> class, which records when
a filter rule matched an event on a ticket.

The attributes of this class are:

=over 12

=item id

The numeric ID of this event

=item FilterRule

The numeric ID of the filter rule which matched (also presented as an
C<RT::FilterRule> object via B<FilterRuleObj>)

=item Ticket

The numeric ID of the ticket whose event matched this rule (also presented
as an C<RT::Ticket> object via B<TicketObj>)

=item Created

The date and time this event occurred (also presented as an C<RT::Date>
object via B<CreatedObj>)

=back

=cut

    package RT::FilterRuleMatch;
    use base 'RT::Record';

    sub Table {'FilterRuleMatches'}

=head1 RT::FilterRuleMatch METHODS

Note that additional methods will be available, inherited from
C<RT::Record>.

=cut

=head2 Create FilterRule => ID, Ticket => ID

Create a new filter rule match object with the supplied properties, as
described above.  The I<FilterRule> and I<Ticket> can be passed as integer
IDs or as C<RT::FilterRule> and C<RT::Ticket> objects.

Returns ( I<$id>, I<$message> ), where I<$id> is the ID of the new object,
which will be undefined if there was a problem.

=cut

    sub Create {
        my $self = shift;
        my %args = (
            'FilterRule' => 0,
            'Ticket'     => 0,
            @_
        );

        $args{'FilterRule'} = $args{'FilterRule'}->id
            if ( ( ref $args{'FilterRule'} )
            && UNIVERSAL::isa( $args{'FilterRule'}, 'RT::FilterRule' ) );
        $args{'Ticket'} = $args{'Ticket'}->id
            if ( ( ref $args{'Ticket'} )
            && UNIVERSAL::isa( $args{'Ticket'}, 'RT::Ticket' ) );

        $RT::Handle->BeginTransaction();
        my ( $id, $msg ) = $self->SUPER::Create(%args);
        unless ($id) {
            $RT::Handle->Rollback();
            return ( undef, $msg );
        }
        $RT::Handle->Commit();

        return ( $id,
            $self->loc( 'Filter rule match [_1] created', $self->id ) );
    }

=head2 FilterRuleObj

Return an C<RT::FilterRule> object containing this filter rule match's
matching filter rule.

=cut

    sub FilterRuleObj {
        my ($self) = @_;

        if (   !$self->{'_FilterRule_obj'}
            || !$self->{'_FilterRule_obj'}->id )
        {

            $self->{'_FilterRule_obj'}
                = RT::FilterRule->new( $self->CurrentUser );
            my ($result)
                = $self->{'_FilterRule_obj'}
                ->Load( $self->__Value('FilterRule') );
        }
        return ( $self->{'_FilterRule_obj'} );
    }

=head2 TicketObj

Return an C<RT::Ticket> object containing this filter rule match's matching
ticket.

=cut

    sub TicketObj {
        my ($self) = @_;

        if (   !$self->{'_Ticket_obj'}
            || !$self->{'_Ticket_obj'}->id )
        {

            $self->{'_Ticket_obj'} = RT::Ticket->new( $self->CurrentUser );
            my ($result)
                = $self->{'_Ticket_obj'}->Load( $self->__Value('Ticket') );
        }
        return ( $self->{'_Ticket_obj'} );
    }

=head2 _CoreAccessible

Return a hashref describing the attributes of the database table for the
C<RT::FilterRuleMatch> class.

=cut

    sub _CoreAccessible {
        return {

            'id' => {
                read       => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => ''
            },

            'FilterRule' => {
                read       => 1,
                write      => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Ticket' => {
                read       => 1,
                write      => 1,
                sql_type   => 4,
                length     => 11,
                is_blob    => 0,
                is_numeric => 1,
                type       => 'int(11)',
                default    => '0'
            },

            'Created' => {
                read       => 1,
                auto       => 1,
                sql_type   => 11,
                length     => 0,
                is_blob    => 0,
                is_numeric => 0,
                type       => 'datetime',
                default    => ''
            }
        };
    }

    RT::Base->_ImportOverlays();
}

{

=head1 Internal package RT::FilterRuleMatches

This package provides the C<RT::FilterRuleMatches> class, which describes a
collection of filter rule matches.

=cut

    package RT::FilterRuleMatches;

    use base 'RT::SearchBuilder';

    sub Table {'FilterRuleMatches'}

    RT::Base->_ImportOverlays();
}

1;
