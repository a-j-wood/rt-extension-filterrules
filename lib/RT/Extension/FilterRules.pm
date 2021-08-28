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

    # TODO: load all filter rule groups
    # TODO: for each rule group, check it's eligible
    # TODO: for each eligible group, apply its rules

    return 1;
}

{

=head1 Internal package RT::FilterRuleGroup

This package provides the C<RT::FilterRuleGroup> object, which describes a
group of filter rules through which a ticket will be passed if it meets the
basic conditions of the group.

The properties of a filter rule group object are:

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
objects whose sort order is zero.  If any of these rules match, the ticket
is eligible to be passed through the rules for this group.

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

=cut

    sub Create {
        my $self = shift;
        my @args = (
            'Name' => '',
            @_
        );

        # TODO: writeme
    }

    sub CanMatchQueuesObj {
        my ($self) = @_;

        # TODO: writeme
    }

    sub CanTransferQueuesObj {
        my ($self) = @_;

        # TODO: writeme
    }

    sub CanUseGroupsObj {
        my ($self) = @_;

        # TODO: writeme
    }

    sub SetSortOrder {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetName {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetCanMatchQueues {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetCanTransferQueues {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetCanUseGroups {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetDisabled {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub FilterRules {
        my ($self) = @_;

        # TODO: writeme
    }

    sub AddFilterRule {
        my ( $self, @args ) = @_;

        # TODO: writeme
    }

    sub Delete {
        my ($self) = @_;

        # TODO: writeme
    }

    sub CheckConditions {
        my $self = shift;
        my @args = (@_);

        # TODO: writeme
    }

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

This package provides the C<RT::FilterRuleGroups> object, which describes a
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

This package provides the C<RT::FilterRule> object, which describes a filter
rule - the conditions it must not meet, the conditions it must meet, and the
actions to perform on the ticket if the rule matches.

The properties of a filter rule object are:

=over 20

=item id

The numeric ID of this filter rule

=item FilterRuleGroup

The numeric ID of the filter rule group to which this filter rule belongs
(also presented as an C<RT::FilterRuleGroup> object via
B<FilterRuleGroupObj>)

=item SortOrder

The order of processing - filter rules with a lower sort order are processed
first; a sort order of zero means that this filter rule is used to determine
whether the whole filter rule group is applicable

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
for filter rule group applicability rules (where B<SortOrder> is 0) (TODO:
define format)

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

=cut

    sub Create {
        my $self = shift;
        my @args = (
            'Name' => '',
            @_
        );

        # TODO: writeme
    }

    sub FilterRuleGroupObj {
        my ($self) = @_;

        # TODO: writeme
    }

    sub SetSortOrder {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetName {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetTriggerType {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetStopIfMatched {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetConflicts {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetRequirements {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetActions {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub SetDisabled {
        my ( $self, $NewValue ) = @_;

        # TODO: writeme
    }

    sub Delete {
        my ($self) = @_;

        # TODO: writeme
    }

    sub MatchHistory {
        my ($self) = @_;

        # TODO: writeme
    }

    sub Match {
        my $self = shift;
        my @args = (@_);

        # TODO: writeme
    }

    sub RecordMatch {
        my $self = shift;
        my @args = (@_);

        # TODO: writeme
    }

    sub PerformActions {
        my ($self) = @_;

        # TODO: writeme
    }

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
                }

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

This package provides the C<RT::FilterRules> object, which describes a
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

This package provides the C<RT::FilterRuleMatch> object, which records when
a filter rule matched an event on a ticket.

The properties of a filter rule match object are:

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

=cut

    sub Create {
        my $self = shift;
        my @args = (
            'FilterRule' => 0,
            'Ticket'     => 0,
            @_
        );

        # TODO: writeme
    }

    sub FilterRuleObj {
        my ($self) = @_;

        # TODO: writeme
    }

    sub TicketObj {
        my ($self) = @_;

        # TODO: writeme
    }

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

This package provides the C<RT::FilterRuleMatches> object, which describes a
collection of filter rule matches.

=cut

    package RT::FilterRuleMatches;

    use base 'RT::SearchBuilder';

    sub Table {'FilterRuleMatches'}

    RT::Base->_ImportOverlays();
}

1;
