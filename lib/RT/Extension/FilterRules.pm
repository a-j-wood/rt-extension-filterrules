use strict;
use warnings;

package RT::Extension::FilterRules;

our $VERSION = '0.01';

our @ConditionProviders = ();
our @ActionProviders = ();


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

=item B<Set up the database>

After running C<make install> for the first time, you will need to create
the database tables for this extension.  Use C<etc/schema-mysql.sql> for
MySQL or MariaDB, or C<etc/schema-postgresql.sql> for PostgreSQL.

=item B<Edit your> F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::FilterRules');

=item B<Clear your Mason cache>

    rm -rf /opt/rt4/var/mason_data/obj

=item B<Restart your web server>

=item B<Add the processing scrip>

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

=item B<Set up some filter rule groups>

Rule groups are set up by the RT administrator under I<Admin> - I<Filter
rule groups>.

From that page, the RT administrator can also automatically create the
general processing scrip which runs tickets through the filter rules.
B<Make sure this scrip is created>, otherwise none of the filter rules will
actually do anything.

=back

=head1 TUTORIAL

For the purposes of this tutorial, we assume that you have these queues:

=over 16

=item B<"General">

- for general queries;

=item B<"Technical">

- for more technical matters to be escalated to.

=back

We also assume that you have these user-defined groups set up:

=over 30

=item B<"Service desk">

- containing all first-line analysts;

=item B<"Service desk management">

- containing the leadership team for the service desk;

=item B<"Third line">

- containing all technical teams.

=back

These are only examples for illustration, there is no need for your system
to be set up this way to use it with this extension.

=head2 Create a new filter rule group

=over

=item 1.

As a superuser, go to I<Admin> - I<Filter rule groups> - I<Create>.

=item 2.

Provide a name for the new filter rule group, such as
I<"General inbound message filtering">, and click on the B<Create> button.

=item 3.

Now that the filter rule group has been created, you can define the queues
and groups it can use.

Next to I<Queues to allow in match rules>, select your I<General> queue and
click on the B<Add queue> button.

=item 4.

You will see the I<General> queue is now listed next to I<Queues to allow in
match rules>.  If you select it and click on the B<Save Changes> button, the
queue will be removed from the list.

If you tried that, add it back again before the next step.

=item 5.

Rules in this filter rule group need to be able to transfer tickets into the
I<Technical> queue, so next to I<Queues to allow as transfer destinations>,
select your I<Technical> queue and click on the B<Add queue> button.

=item 6.

Add the I<Service desk> and I<Third line> groups to
I<Groups to allow in rule actions> to be able to use them in filter rules,
such as sending notifications to members of those groups.

=back

After saving your changes, go back to I<Admin> - I<Filter rule groups>, and
you will see your new filter rule group and its settings.

Once you have more than one, you can move them up and down in the list to
control the order in which they are processed, using the I<Up> and I<Down>
links at the right.

=head2 Set the conditions for the filter rule group

A filter rule group will not process any messages unless its conditions are
met.  Each one starts off with no conditions, so will remain inactive until
you define some.

From I<Admin> - I<Filter rule groups>, click on your new filter rule group,
and then choose I<Conditions> from the page menu at the top.

(TODO)

=head2 Delegate control of the filter rule group

In this example, the new filter rule group you created above, called
I<General inbound message filtering>, is going to be managed by the
service desk management team.  This means that you want them to be able to
create, update, and delete filter rules within that group with no
assistance.

We will also allow the service desk team to view the filter rules, so that
they have visibility of what automated processing is being applied to
tickets they are receiving.

=over

=item 1.

From I<Admin> - I<Filter rule groups>, click on your new filter rule group,
and then choose I<Group Rights> from the page menu at the top.

=item 2.

In the text box under I<ADD GROUP> at the bottom left, type
I<"Service desk management"> but do not hit Enter.

=item 3.

On the right side of the screen, under I<Rights for Staff>, select all of
the rights so that the management team can fully control the filter rules in
this filter rule group.

=item 4.

Click on the B<Save Changes> button at the bottom right to grant these
rights.

=item 5.

In the text box under I<ADD GROUP> at the bottom left, type
I<"Service desk"> but do not hit Enter.

=item 6.

On the right side of the screen, under I<Rights for Staff>, select only the
I<View filter rules> right, so that the service desk analysts can only view
these filter rules, not edit them.

=item 7.

Click on the B<Save Changes> button at the bottom right to grant these
rights.

=back

Members of the I<Service desk management> group will now be able to manage
the filter rules of the I<General inbound message filtering> filter rule
group, under the I<Tools> - I<Filter rules> menu.

Members of the I<Service desk> group will be able to see those rules there
too, but will not be able to modify them.

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

    # Perform the non-notification actions we have accumulated.
    #
    foreach ( grep { not $_->IsNotification } @$Actions ) {
        $_->Perform();
    }

    # Perform the notification actions we have accumulated.
    #
    foreach ( grep { $_->IsNotification } @$Actions ) {
        $_->Perform();
    }

    return 1;
}

=head2 ConditionTypes $UserObj

Return an array of all available condition types, with the names localised
for the given user.

Each array entry is a hash reference containing these keys:

=over 18

=item B<ConditionType>

The internal name for this condition type; this should follow the naming
convention for variables - start with a letter, no spaces, and so on - and
it must be unique

=item B<Name>

Localised name, to be displayed to the operator

=item B<TriggerTypes>

Array reference listing the trigger actions with which this condition can be
used (as listed under the I<TriggerType> attribute of the C<RT::FilterRule>
class below), or an empty array reference (or undef) if this condition type
can be used with all trigger types

=item B<ValueType>

Which type of value the condition expects as a parameter - one of
I<None>, I<String>, I<Integer>, I<Email>, I<Queue>, or I<Status>

=item B<Function>

If present, this is a code reference which will be called to check this
condition; this code reference will be passed a hash of the parameters from
inside an C<RT::FilterRule::Condition> object, plus I<Check>, as it will be
called from the B<TestSingleValue> method of C<RT::FilterRule::Condition>

=back

If I<Function> is not present, the B<TestSingleValue> method of
C<RT::FilterRule::Condition> will attempt to call an
C<RT::FilterRule::Condition> method of the same name as I<ConditionType>
with C<_> prepended, returning a failed match (and logging an error) if such
a method does not exist.

Note that if I<ConditionType> contains the string C<CustomField>, then the
condition will require the person creating the condition to select an
applicable custom field.

=cut

sub ConditionTypes {
    my ( $Package, $UserObj ) = @_;
    my @ConditionTypes = ();

    push @ConditionTypes,
        (
        {   'ConditionType' => 'All',
            'Name'          => $UserObj->loc('Always match'),
            'TriggerTypes'  => [],
            'ValueType'     => 'None'
        },
        {   'ConditionType' => 'InQueue',
            'Name'          => $UserObj->loc('In queue'),
            'TriggerTypes'  => ['Create'],
            'ValueType'     => 'Queue'
        },
        {   'ConditionType' => 'FromQueue',
            'Name'          => $UserObj->loc('Moving from queue'),
            'TriggerTypes'  => ['QueueMove'],
            'ValueType'     => 'Queue'
        },
        {   'ConditionType' => 'ToQueue',
            'Name'          => $UserObj->loc('Moving to queue'),
            'TriggerTypes'  => ['QueueMove'],
            'ValueType'     => 'Queue'
        },
        {   'ConditionType' => 'RequestorEmailIs',
            'Name'          => $UserObj->loc('Requestor email address is'),
            'TriggerTypes'  => [],
            'ValueType'     => 'Email'
        },
        {   'ConditionType' => 'RequestorEmailDomainIs',
            'Name'          => $UserObj->loc('Requestor email domain is'),
            'TriggerTypes'  => [],
            'ValueType'     => 'String'
        },
        {   'ConditionType' => 'RecipientEmailIs',
            'Name'          => $UserObj->loc('Recipient email address is'),
            'TriggerTypes'  => ['Create'],
            'ValueType'     => 'Email'
        },
        {   'ConditionType' => 'SubjectContains',
            'Name'          => $UserObj->loc('Subject contains'),
            'TriggerTypes'  => [],
            'ValueType'     => 'String'
        },
        {   'ConditionType' => 'SubjectOrBodyContains',
            'Name' => $UserObj->loc('Subject or message body contains'),
            'TriggerTypes' => [],
            'ValueType'    => 'String'
        },
        {   'ConditionType' => 'BodyContains',
            'Name'          => $UserObj->loc('Message body contains'),
            'TriggerTypes'  => [],
            'ValueType'     => 'String'
        },
        {   'ConditionType' => 'HeaderContains',
            'Name'          => $UserObj->loc('Any message header contains'),
            'TriggerTypes'  => ['Create'],
            'ValueType'     => 'String'
        },
        {   'ConditionType' => 'HasAttachment',
            'Name'          => $UserObj->loc('Has an attachment'),
            'TriggerTypes'  => ['Create'],
            'ValueType'     => 'None'
        },
        {   'ConditionType' => 'PriorityIs',
            'Description'   => $UserObj->loc('Priority is'),
            'TriggerTypes'  => [],
            'ValueType'     => 'Integer'
        },
        {   'ConditionType' => 'PriorityUnder',
            'Description'   => $UserObj->loc('Priority less than'),
            'TriggerTypes'  => [],
            'ValueType'     => 'Integer'
        },
        {   'ConditionType' => 'PriorityOver',
            'Description'   => $UserObj->loc('Priority greater than'),
            'TriggerTypes'  => [],
            'ValueType'     => 'Integer'
        },
        {   'ConditionType' => 'CustomFieldIs',
            'Name'          => $UserObj->loc('Custom field exactly matches'),
            'TriggerTypes'  => [],
            'ValueType'     => 'String'
        },
        {   'ConditionType' => 'CustomFieldContains',
            'Name'          => $UserObj->loc('Custom field contains'),
            'TriggerTypes'  => [],
            'ValueType'     => 'String'
        },
        {   'ConditionType' => 'StatusIs',
            'Name'          => $UserObj->loc('Status is'),
            'TriggerTypes'  => [],
            'ValueType'     => 'Status'
        },
        );

    foreach (@ConditionProviders) {
        push @ConditionTypes, $_->($UserObj);
    }

    return @ConditionTypes;
}

=head2 ActionTypes $UserObj

Return an array of all available action types, with the names localised for
the given user.

Each array entry is a hash reference containing these keys:

=over 18

=item B<ActionType>

The internal name for this action type; this should follow the naming
convention for variables - start with a letter, no spaces, and so on - and
it must be unique

=item B<Name>

Localised name, to be displayed to the operator

=item B<ValueType>

Which type of value the action expects as a parameter - one of I<None>,
I<String>, I<Integer>, I<Email>, I<Group>, I<Queue>, I<Status>, or I<HTML>

=item B<Function>

If present, this is a code reference which will be called to perform this
action; this code reference will be passed a hash of the parameters from
inside an C<RT::FilterRule::Action> object, as it will be called from the
B<Perform> method of C<RT::FilterRule::Action>

=back

If I<Function> is not present, the B<Perform> method of
C<RT::FilterRule::Action> will attempt to call an C<RT::FilterRule::Action>
method of the same name as I<ActionType> with C<_> prepended, returning a
failed action (and logging an error) if such a method does not exist.

Note that:

=over

=item *

If I<ActionType> contains the string C<CustomField>, then a custom field
must be selected by the person creating the action, separately to the value,
and this will populate the C<RT::FilterRule::Action>'s I<CustomField>
attribute;

=item *

If I<ActionType> contains the string C<NotifyEmail>, then an email address
must be entered by the person creating the action, separately to the value,
and this will populate the C<RT::FilterRule::Action>'s I<Notify> attribute;

=item *

If I<ActionType> contains the string C<NotifyGroup>, then an RT group must
be selected by the person creating the action, separately to the value, and
this will populate the C<RT::FilterRule::Action>'s I<Notify> attribute.

=back

=cut

sub ActionTypes {
    my ( $Package, $UserObj ) = @_;
    my @ActionTypes = ();

    push @ActionTypes,
        (
        {   'ActionType' => 'None',
            'Name'       => $UserObj->loc('Take no action'),
            'ValueType'  => 'None'
        },
        {   'ActionType' => 'SubjectPrefix',
            'Name'       => $UserObj->loc('Add prefix to subject'),
            'ValueType'  => 'String'
        },
        {   'ActionType' => 'SubjectSuffix',
            'Name'       => $UserObj->loc('Add suffix to subject'),
            'ValueType'  => 'String'
        },
        {   'ActionType' => 'SubjectRemoveMatch',
            'Name'       => $UserObj->loc('Remove string from subject'),
            'ValueType'  => 'String'
        },
        {   'ActionType' => 'SubjectSet',
            'Name'       => $UserObj->loc('Replace subject'),
            'ValueType'  => 'String'
        },
        {   'ActionType' => 'PrioritySet',
            'Name'       => $UserObj->loc('Set priority'),
            'ValueType'  => 'Integer'
        },
        {   'ActionType' => 'PriorityAdd',
            'Name'       => $UserObj->loc('Add to priority'),
            'ValueType'  => 'Integer'
        },
        {   'ActionType' => 'PrioritySubtract',
            'Name'       => $UserObj->loc('Subtract from priority'),
            'ValueType'  => 'Integer'
        },
        {   'ActionType' => 'StatusSet',
            'Name'       => $UserObj->loc('Set status'),
            'ValueType'  => 'Status'
        },
        {   'ActionType' => 'QueueSet',
            'Name'       => $UserObj->loc('Move to queue'),
            'ValueType'  => 'Queue'
        },
        {   'ActionType' => 'CustomFieldSet',
            'Name'       => $UserObj->loc('Set custom field value'),
            'ValueType'  => 'String'
        },
        {   'ActionType' => 'RequestorAdd',
            'Name'       => $UserObj->loc('Add requestor'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'RequestorRemove',
            'Name'       => $UserObj->loc('Remove requestor'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'CcAdd',
            'Name'       => $UserObj->loc('Add CC'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'CcAddGroup',
            'Name'       => $UserObj->loc('Add group as a CC'),
            'ValueType'  => 'Group'
        },
        {   'ActionType' => 'CcRemove',
            'Name'       => $UserObj->loc('Remove CC'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'AdminCcAdd',
            'Name'       => $UserObj->loc('Add AdminCC'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'AdminCcAddGroup',
            'Name'       => $UserObj->loc('Add group as an AdminCC'),
            'ValueType'  => 'Group'
        },
        {   'ActionType' => 'AdminCcRemove',
            'Name'       => $UserObj->loc('Remove AdminCC'),
            'ValueType'  => 'Email'
        },
        {   'ActionType' => 'Reply',
            'Name'       => $UserObj->loc('Reply to ticket'),
            'ValueType'  => 'HTML'
        },
        {   'ActionType' => 'NotifyEmail',
            'Name' => $UserObj->loc('Send notification to an email address'),
            'ValueType' => 'HTML'
        },
        {   'ActionType' => 'NotifyGroup',
            'Name' => $UserObj->loc('Send notification to RT group members'),
            'ValueType' => 'HTML'
        },
        );

    foreach (@ActionProviders) {
        push @ActionTypes, $_->($UserObj);
    }

    return @ActionTypes;
}

=head2 AddConditionProvider CODEREF

Add a condition provider, which is a function accepting an
C<RT::CurrentUser> object and returning an array of the same form as the
B<ConditionTypes> method.

The B<ConditionTypes> method will call the provided code reference and
append its returned values to the array it returns.

Other extensions can call this method to add their own filter condition
types.

=cut

sub AddConditionProvider {
    my ($Package, $CodeRef) = @_;
    push @ConditionProviders, $CodeRef;
}

=head2 AddActionProvider CODEREF

Add an action provider, which is a function accepting an
C<RT::CurrentUser> object and returning an array of the same form as the
B<ActionTypes> method.

The B<ActionTypes> method will call the provided code reference and append
its returned values to the array it returns.

Other extensions can call this method to add their own filter action types.

=cut

sub AddActionProvider {
    my ($Package, $CodeRef) = @_;
    push @ActionProviders, $CodeRef;
}

{

=head1 Internal package RT::FilterRuleGroup

This package provides the C<RT::FilterRuleGroup> class, which describes a
group of filter rules through which a ticket will be passed if it meets the
basic conditions of the group.

The attributes of this class are:

=over 20

=item B<id>

The numeric ID of this filter rule group

=item B<SortOrder>

The order of processing - filter rule groups with a lower sort order are
processed first

=item B<Name>

The displayed name of this filter rule group

=item B<CanMatchQueues>

The queues which rules in this rule group are allowed to use in their
conditions, as a comma-separated list of queue IDs (also presented as an
C<RT::Queues> object via B<CanMatchQueuesObj>)

=item B<CanTransferQueues>

The queues which rules in this rule group are allowed to use as transfer
destinations in their actions, as a comma-separated list of queue IDs (also
presented as an C<RT::Queues> object via B<CanTransferQueuesObj>)

=item B<CanUseGroups>

The groups which rules in this rule group are allowed to use in match
conditions and actions, as a comma-separated list of group IDs (also
presented as an C<RT::Groups> object via B<CanUseGroupsObj>)

=item B<Creator>

The numeric ID of the creator of this filter rule group (also presented as
an C<RT::User> object via B<CreatorObj>)

=item B<Created>

The date and time this filter rule group was created (also presented as an
C<RT::Date> object via B<CreatedObj>)

=item B<LastUpdatedBy>

The numeric ID of the user who last updated the properties of this filter
rule group (also presented as an C<RT::User> object via B<LastUpdatedByObj>)

=item B<LastUpdated>

The date and time this filter rule group's properties were last updated
(also presented as an C<RT::Date> object via B<LastUpdatedObj>)

=item B<Disabled>

Whether this filter rule group is disabled; the filter rule group is active
unless this property is true

=back

The basic conditions of the filter rule group are defined by its
B<GroupConditions>, which is a collection of C<RT::FilterRule> objects whose
B<IsGroupCondition> attribute is true.  If I<any> of these rules match, the
ticket is eligible to be passed through the rules for this group.

The filter rules for this group are presented via B<FilterRules>, which is a
collection of C<RT::FilterRule> objects.

Filter rule groups themselves can only be created, modified, and deleted by
users with the I<SuperUser> right.

The following rights can be assigned to individual filter rule groups to
delegate control of the filter rules within them:

=over 18

=item B<SeeFilterRule>

View the filter rules in this filter rule group

=item B<ModifyFilterRule>

Modify existing filter rules in this filter rule group

=item B<CreateFilterRule>

Create new filter rules in this filter rule group

=item B<DeleteFilterRule>

Delete filter rules from this filter rule group

=back

These are assigned using the rights pages of the filter rule group, under
I<Admin> - I<Filter rule groups>.

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
        $Collection->UnLimit();
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

Add a condition to this filter rule group; calls the C<RT::FilterRule>
B<Create> method, overriding the I<FilterRuleGroup> and I<IsGroupCondition>
parameters, and returns its output.

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
        $Collection->UnLimit();
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

Add a filter rule to this filter rule group; calls the C<RT::FilterRule>
B<Create> method, overriding the I<FilterRuleGroup> and I<IsGroupCondition>
parameters, and returns its output.

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
        $Collection->FindAllRows();
        $Collection->GotoFirstItem();
        while ( $Item = $Collection->Next ) {
            $Item->Delete();
        }

        # Delete the filter rules.
        #
        $Collection = $self->FilterRules();
        $Collection->FindAllRows();
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
            'Matches'         => [],
            'TriggerType'     => '',
            'From'            => 0,
            'To'              => 0,
            'Ticket'          => 0,
            'IncludeDisabled' => 0,
            @_
        );
        my ( $Collection, $Item );

        $Collection = $self->GroupConditions();
        $Collection->FindAllRows();
        $Collection->Limit(
            'FIELD'    => 'Disabled',
            'VALUE'    => 0,
            'OPERATOR' => '='
        ) if ( not $args{'IncludeDisabled'} );
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
            'Matches'         => [],
            'Actions'         => [],
            'TriggerType'     => '',
            'From'            => 0,
            'To'              => 0,
            'Ticket'          => 0,
            'IncludeDisabled' => 0,
            'RecordMatch'     => 0,
            @_
        );
        my ( $Collection, $Item, $MatchesFound );

        $MatchesFound = 0;

        $Collection = $self->FilterRules();
        $Collection->FindAllRows();
        $Collection->Limit(
            'FIELD'    => 'Disabled',
            'VALUE'    => 0,
            'OPERATOR' => '='
        ) if ( not $args{'IncludeDisabled'} );
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
                $Item->RecordMatch( 'Ticket' => $args{'Ticket'} )
                    if ( $args{'RecordMatch'} );
                return 1 if ( $Item->StopIfMatched );
            }
        }

        return $MatchesFound;
    }

=head2 MoveUp

Move this filter rule group up in the sort order so it is processed earlier. 
Returns ( I<$ok>, I<$message> ).

=cut

    sub MoveUp {
        my $self = shift;
        return $self->Move(-1);
    }

=head2 MoveDown

Move this filter rule group down in the sort order so it is processed later. 
Returns ( I<$ok>, I<$message> ).

=cut

    sub MoveDown {
        my $self = shift;
        return $self->Move(1);
    }

=head2 Move OFFSET

Change this filter rule group's sort order by the given I<OFFSET>.

=cut

    sub Move {
        my ( $self, $Offset ) = @_;

        return ( 1, $self->loc('Not moved') ) if ( $Offset == 0 );

        my $Collection = RT::FilterRuleGroups->new( $self->CurrentUser );
        $Collection->UnLimit();
        $Collection->FindAllRows();
        $Collection->OrderByCols( { FIELD => 'SortOrder', ORDER => 'ASC' } );
        $Collection->GotoFirstItem();
        my @CollectionOrder = ();
        while ( my $Item = $Collection->Next ) {
            push @CollectionOrder, { 'Object' => $Item, 'id' => $Item->id };
        }

        my $SelfId          = $self->id;
        my $CurrentPosition = -1;
        for ( my $Index = 0; $Index <= $#CollectionOrder; $Index++ ) {
            next if ( $CollectionOrder[$Index]->{'id'} != $SelfId );
            $CurrentPosition = $Index;
        }
        return ( 0, $self->loc('Failed to find current position') )
            if ( $CurrentPosition < 0 );

        my $NewPosition = $CurrentPosition + $Offset;
        if ( $NewPosition < 0 ) {
            return ( 0,
                $self->loc("Can not move up. It's already at the top") );
        } elsif ( $NewPosition > $#CollectionOrder ) {
            return ( 0,
                $self->loc("Can not move down. It's already at the bottom") );
        }

        my $Swap = $CollectionOrder[$CurrentPosition];
        $CollectionOrder[$CurrentPosition] = $CollectionOrder[$NewPosition];
        $CollectionOrder[$NewPosition]     = $Swap;

        for ( my $Index = 0; $Index <= $#CollectionOrder; $Index++ ) {
            $CollectionOrder[$Index]->{'Object'}->SetSortOrder( 1 + $Index );
        }

        return ( 1, $self->loc('Moved') );
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

        # NB we don't record a transaction for sort order changes, since
        # they are very frequent.
        #
        if ( ( $args{'Field'} || '' ) eq 'Disabled' ) {
            my ( $txn_id, $txn_msg, $txn )
                = $self->_NewTransaction(
                Type => $args{'Value'} ? 'Disabled' : 'Enabled' );
            if ( not $txn_id ) {
                $RT::Handle->Rollback();
                return ( 0, $self->loc( 'Internal error: [_1]', $txn_msg ) );
            }
        } elsif ( ( $args{'Field'} || '' ) ne 'SortOrder' ) {
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

=head2 CurrentUserCanSee

Return true if the current user has permission to see this object.

=cut

    sub CurrentUserCanSee {
        my $self = shift;
        return $self->CurrentUserHasRight('SuperUser');
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
        $self->OrderByCols( { FIELD => 'SortOrder', ORDER => 'ASC' } );
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

=item B<id>

The numeric ID of this filter rule

=item B<FilterRuleGroup>

The numeric ID of the filter rule group to which this filter rule belongs
(also presented as an C<RT::FilterRuleGroup> object via
B<FilterRuleGroupObj>)

=item B<IsGroupCondition>

Whether this is a filter rule which describes conditions under which the
filter rule group as a whole is applicable (true), or a filter rule for
processing an event through and performing actions if matched (false).

This is true for filter rules under a rule group's B<GroupConditions>, and
false for filter rules under a rule group's B<FilterRules>.

This attribute is set automatically when a C<RT::FilterRule> object is
created via the B<AddGroupCondition> and B<AddFilterRule> methods of
C<RT::FilterRuleGroup>.

=item B<SortOrder>

The order of processing - filter rules with a lower sort order are processed
first

=item B<Name>

The displayed name of this filter rule

=item B<TriggerType>

The type of action which triggers this filter rule - one of:

=over 10

=item I<Create>

Consider this rule on ticket creation

=item I<QueueMove>

Consider this rule when the ticket moves between queues

=back

=item B<StopIfMatched>

If this is true, then processing of the remaining rules in this filter rule
group should be skipped if this rule matches

=item B<Conflicts>

Conditions which, if met, mean this rule cannot match; this is presented as
an array of C<RT::FilterRule::Condition> objects, and stored as
a Base64-encoded string encoding an array ref containing hash refs.

=item B<Requirements>

Conditions which, if any are met, mean this rule matches, so long as none of
the conflict conditions above have matched; this is also presented as an
array of C<RT::FilterRule::Condition> objects, and stored in the
same way as above.

=item B<Actions>

Actions to carry out on the ticket if the rule matches (this field is unused
for filter rule group applicability rules, i.e.  where B<IsGroupCondition>
is 1); it is presented as an array of C<RT::FilterRule::Action>
objects, and stored as a Base64-encoded string encoding an array ref
containing hash refs.

=item B<Creator>

The numeric ID of the creator of this filter rule (also presented as an
C<RT::User> object via B<CreatorObj>)

=item B<Created>

The date and time this filter rule was created (also presented as an
C<RT::Date> object via B<CreatedObj>)

=item B<LastUpdatedBy>

The numeric ID of the user who last updated the properties of this filter
rule (also presented as an C<RT::User> object via B<LastUpdatedByObj>)

=item B<LastUpdated>

The date and time this filter rule's properties were last updated (also
presented as an C<RT::Date> object via B<LastUpdatedObj>)

=item B<Disabled>

Whether this filter rule is disabled; the filter rule is active unless this
property is true

=back

=cut

    package RT::FilterRule;
    use base 'RT::Record';

    sub Table {'FilterRules'}

    use RT::Transactions;

    use Storable;
    use MIME::Base64;

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
            && UNIVERSAL::isa( $args{'FilterRuleGroup'},
                'RT::FilterRuleGroup' ) );

        foreach my $Attribute ( 'Conflicts', 'Requirements', 'Actions' ) {
            my $Value = $args{$Attribute};
            next if ( not ref $Value );
            my @NewList = map { $_->Properties() } @$Value;
            $Value = '';
            eval {
                $Value
                    = MIME::Base64::encode_base64(
                    Storable::nfreeze( \@NewList ) );
            };
            if ($@) {
                RT->Logger->error(
                    "RT::Extension::FilterRules - failed to serialise RT::FilterRule attribute $Attribute"
                );
            }
            $self->{ '_' . $Attribute } = $args{$Attribute};
            $args{$Attribute} = $Value;
        }

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

=head2 Conflicts

Return an array of C<RT::FilterRule::Condition> objects describing the
conditions which, if any are met, mean this rule cannot match.

=cut

    sub Conflicts {
        my ($self) = @_;
        if ( not defined $self->{'_Conflicts'} ) {
            my $CurrentValue = [];

            # Thaw the encoded value
            eval {
                $CurrentValue
                    = Storable::thaw(
                    MIME::Base64::decode_base64( $self->_Value('Conflicts') )
                    );
            };
            if ($@) {
                RT->Logger->error(
                    "RT::Extension::FilterRules - failed to deserialise RT::FilterRule attribute Conflicts"
                );
            }

            # Convert the thawed data from hashrefs into objects
            $self->{'_Conflicts'} = [];
            foreach (@$CurrentValue) {
                my $NewObject
                    = RT::FilterRule::Condition->new( $self->CurrentUser,
                    %$_ );
                push @{ $self->{'_Conflicts'} }, $NewObject;
            }
        }
        return @{ $self->{'_Conflicts'} };
    }

=head2 SetConflicts CONDITION, CONDITION, ...

Set the conditions which, if any are met, mean this rule cannot match. 
Expects an array of C<RT::FilterRule::Condition> objects.

=cut

    sub SetConflicts {
        my ( $self, @Conditions ) = @_;

        my @NewList = map { $_->Properties() } @Conditions;
        my $NewValue = '';
        eval {
            $NewValue
                = MIME::Base64::encode_base64(
                Storable::nfreeze( \@NewList ) );
        };

        if ($@) {
            RT->Logger->error(
                "RT::Extension::FilterRules - failed to serialise RT::FilterRule attribute Conflicts"
            );
            return ( 0, $self->loc('Failed to serialise conflicts') );
        }

        $self->{'_Conflicts'} = [@Conditions];
        return $self->_Set(
            'Field' => 'Conflicts',
            'Value' => $NewValue
        );
    }

=head2 Requirements

Return an array of C<RT::FilterRule::Condition> objects describing the
conditions which, if any are met, mean this rule matches, so long as none of
the conflict conditions above have matched.

=cut

    sub Requirements {
        my ($self) = @_;
        if ( not defined $self->{'_Requirements'} ) {
            my $CurrentValue = [];

            # Thaw the encoded value
            eval {
                $CurrentValue = Storable::thaw(
                    MIME::Base64::decode_base64(
                        $self->_Value('Requirements')
                    )
                );
            };
            if ($@) {
                RT->Logger->error(
                    "RT::Extension::FilterRules - failed to deserialise RT::FilterRule attribute Requirements"
                );
            }

            # Convert the thawed data from hashrefs into objects
            $self->{'_Requirements'} = [];
            foreach (@$CurrentValue) {
                my $NewObject
                    = RT::FilterRule::Condition->new( $self->CurrentUser,
                    %$_ );
                push @{ $self->{'_Requirements'} }, $NewObject;
            }
        }
        return @{ $self->{'_Requirements'} };
    }

=head2 SetRequirements CONDITION, CONDITION, ...

Set the conditions which, if any are met, mean this rule matches, so long as
none of the conflict conditions above have matched.  Expects an array of
C<RT::FilterRule::Condition> objects.

=cut

    sub SetRequirements {
        my ( $self, @Conditions ) = @_;

        my @NewList = map { $_->Properties() } @Conditions;
        my $NewValue = '';
        eval {
            $NewValue
                = MIME::Base64::encode_base64(
                Storable::nfreeze( \@NewList ) );
        };

        if ($@) {
            RT->Logger->error(
                "RT::Extension::FilterRules - failed to serialise RT::FilterRule attribute Requirements"
            );
            return ( 0, $self->loc('Failed to serialise conflicts') );
        }

        $self->{'_Requirements'} = [@Conditions];
        return $self->_Set(
            'Field' => 'Requirements',
            'Value' => $NewValue
        );
    }

=head2 Actions

Return an array of C<RT::FilterRule::Action> objects describing the actions
to carry out on the ticket if the rule matches.

=cut

    sub Actions {
        my ($self) = @_;
        if ( not defined $self->{'_Actions'} ) {
            my $CurrentValue = [];

            # Thaw the encoded value
            eval {
                $CurrentValue
                    = Storable::thaw(
                    MIME::Base64::decode_base64( $self->_Value('Actions') ) );
            };
            if ($@) {
                RT->Logger->error(
                    "RT::Extension::FilterRules - failed to deserialise RT::FilterRule attribute Actions"
                );
            }

            # Convert the thawed data from hashrefs into objects
            $self->{'_Actions'} = [];
            foreach (@$CurrentValue) {
                my $NewObject
                    = RT::FilterRule::Action->new( $self->CurrentUser, %$_ );
                push @{ $self->{'_Actions'} }, $NewObject;
            }
        }
        return @{ $self->{'_Actions'} };
    }

=head2 SetActions ACTION, ACTION, ...

Set the actions to carry out on the ticket if the rule matches; this field
is unused for filter rule group applicability rules (where
B<IsGroupCondition> is 1).  Expects an array of C<RT::FilterRule::Action>
objects.

=cut

    sub SetActions {
        my ( $self, @Actions ) = @_;

        my @NewList = map { $_->Properties() } @Actions;
        my $NewValue = '';
        eval {
            $NewValue
                = MIME::Base64::encode_base64(
                Storable::nfreeze( \@NewList ) );
        };

        if ($@) {
            RT->Logger->error(
                "RT::Extension::FilterRules - failed to serialise RT::FilterRule attribute Actions"
            );
            return ( 0, $self->loc('Failed to serialise conflicts') );
        }

        $self->{'_Actions'} = [@Actions];
        return $self->_Set(
            'Field' => 'Actions',
            'Value' => $NewValue
        );
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

=head2 Match Matches => [], Actions => [], TriggerType => TYPE, From => FROM, To => TO, IncludeAll => 0

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

If I<IncludeAll> is true, then all conditions for this filter rule will be
added to I<Matches> regardless of whether they matched; this can be used to
present the operator with details of how an event would be processed.

Each entry added to the I<Matches> array reference will be a hash reference
with these keys:

=over 12

=item B<FilterRule>

This C<RT::FilterRule> object

=item B<Conditions>

An array reference containing one entry for each condition checked from this
filter rule's B<Requirements>, each of which is a hash reference containing
the following keys:

=over 11

=item B<Condition>

The C<RT::FilterRule::Condition> object describing this
condition

=item B<Matched>

Whether this condition matched (this will always be true unless
I<IncludeAll> is true, since the condition wouldn't be included otherwise
because all B<Requirement> conditions must be met for a rule to match)

=item B<Checks>

An array reference containing one entry for each value checked in the
condition (since conditions can have multiple OR values), stopping at the
first match; each entry is a hash reference containing the following keys:

=over 9

=item B<Target>

The target value that the event was checked against

=item B<Matched>

Whether the event's value matched the target value

=back

=back

=item B<Matched>

Whether the whole condition matched (this will always be true unless
I<IncludeAll> was supplied, since the condition wouldn't be included
otherwise)

=back

Each entry added to the I<Actions> array reference will be a hash reference
with these keys:

=over 11

=item B<FilterRule>

This C<RT::FilterRule> object

=item B<Action>

The C<RT::FilterRule::Action> object describing this action

=back

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

=head2 MoveUp

Move this filter rule up in the sort order so it is processed earlier. 
Returns ( I<$ok>, I<$message> ).

=cut

    sub MoveUp {
        my $self = shift;
        return $self->Move(-1);
    }

=head2 MoveDown

Move this filter rule down in the sort order so it is processed later. 
Returns ( I<$ok>, I<$message> ).

=cut

    sub MoveDown {
        my $self = shift;
        return $self->Move(1);
    }

=head2 Move OFFSET

Change this filter rule's sort order by the given I<OFFSET>.

=cut

    sub Move {
        my ( $self, $Offset ) = @_;

        return ( 1, $self->loc('Not moved') ) if ( $Offset == 0 );

        my $Collection = RT::FilterRules->new( $self->CurrentUser );
        $Collection->UnLimit();
        $Collection->Limit(
            'FIELD'    => 'FilterRuleGroup',
            'VALUE'    => $self->FilterRuleGroup,
            'OPERATOR' => '='
        );
        $Collection->Limit(
            'FIELD'    => 'IsGroupCondition',
            'VALUE'    => $self->IsGroupCondition,
            'OPERATOR' => '='
        );
        $Collection->FindAllRows();
        $Collection->OrderByCols( { FIELD => 'SortOrder', ORDER => 'ASC' } );
        $Collection->GotoFirstItem();
        my @CollectionOrder = ();

        while ( my $Item = $Collection->Next ) {
            push @CollectionOrder, { 'Object' => $Item, 'id' => $Item->id };
        }

        my $SelfId          = $self->id;
        my $CurrentPosition = -1;
        for ( my $Index = 0; $Index <= $#CollectionOrder; $Index++ ) {
            next if ( $CollectionOrder[$Index]->{'id'} != $SelfId );
            $CurrentPosition = $Index;
        }
        return ( 0, $self->loc('Failed to find current position') )
            if ( $CurrentPosition < 0 );

        my $NewPosition = $CurrentPosition + $Offset;
        if ( $NewPosition < 0 ) {
            return ( 0,
                $self->loc("Can not move up. It's already at the top") );
        } elsif ( $NewPosition > $#CollectionOrder ) {
            return ( 0,
                $self->loc("Can not move down. It's already at the bottom") );
        }

        my $Swap = $CollectionOrder[$CurrentPosition];
        $CollectionOrder[$CurrentPosition] = $CollectionOrder[$NewPosition];
        $CollectionOrder[$NewPosition]     = $Swap;

        for ( my $Index = 0; $Index <= $#CollectionOrder; $Index++ ) {
            $CollectionOrder[$Index]->{'Object'}->SetSortOrder( 1 + $Index );
        }

        return ( 1, $self->loc('Moved') );
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
        if ( ( $args{'Field'} || '' ) eq 'Disabled' ) {
            my ( $txn_id, $txn_msg, $txn )
                = $self->_NewTransaction(
                Type => $args{'Value'} ? 'Disabled' : 'Enabled' );
            if ( not $txn_id ) {
                $RT::Handle->Rollback();
                return ( 0, $self->loc( 'Internal error: [_1]', $txn_msg ) );
            }
        } elsif ( ( $args{'Field'} || '' ) ne 'SortOrder' ) {
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

=head2 CurrentUserCanSee

Return true if the current user has permission to see this object.

=cut

    sub CurrentUserCanSee {
        my $self = shift;
        return 1
            if (
            $self->FilterRuleGroupObj->CurrentUserHasRight('SuperUser') );
        return 1
            if (
            $self->FilterRuleGroupObj->CurrentUserHasRight('SeeFilterRule') );
        return 1
            if (
            $self->FilterRuleGroupObj->CurrentUserHasRight(
                'ModifyFilterRule')
               );
        return 1
            if (
            $self->FilterRuleGroupObj->CurrentUserHasRight(
                'CreateFilterRule')
               );
        return 1
            if (
            $self->FilterRuleGroupObj->CurrentUserHasRight(
                'DeleteFilterRule')
               );
        return 0;
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

=head1 Internal package RT::FilterRule::Condition

This package provides the C<RT::FilterRule::Condition> class,
which describes a condition in a filter rule and provides methods to match
an event on a ticket against that condition.

Objects of this class are not stored directly in the database, but are
encoded within attributes of C<RT::FilterRule> objects.

=cut

    package RT::FilterRule::Condition;

    use base 'RT::Base';

=head1 RT::FilterRule::Condition METHODS

This class inherits from C<RT::Base>.

=cut

=head2 new $UserObj[, PARAMS...]

Construct and return a new object, given an C<RT::CurrentUser> object.  Any
other parameters are passed to B<Set> below.

=cut

    sub new {
        my ( $proto, $UserObj, @args ) = @_;
        my ( $class, $self );

        $class = ref($proto) || $proto;

        $self = {
            'ConditionType' => 'All',
            'CustomField'   => 0,
            'Values'        => [],
            'TriggerType'   => 'Unspecified',
            'From'          => 0,
            'To'            => 0,
            'Ticket'        => undef,
        };

        bless( $self, $class );

        $self->CurrentUser($UserObj);

        $self->Set(@args);

        return $self;
    }

=head2 Set Key => VALUE, ...

Set parameters of this condition object.  The following parameters define
the condition itself:

=over 15

=item B<ConditionType>

The type of condition, such as I<InQueue>, I<FromQueue>, I<SubjectContains>,
and so on - see the C<RT::Extension::FilterRules> method B<ConditionTypes>.

=item B<CustomField>

The custom field ID associated with this condition, if applicable

=item B<Values>

Array reference containing the list of values to match against, any one of
which will mean the condition has matched

=back

The following parameters define the event being matched against:

=over 

=item B<TriggerType>

The action which triggered this check, such as I<Create> or I<QueueMove>

=item B<From>

The value the ticket is changing from

=item B<To>

The value the ticket is changing to (the same as I<From> on ticket creation)

=item B<Ticket>

The ticket ID or C<RT::Ticket> object to match the condition against

=back

This method returns nothing.

(TODO)

=cut

    sub Set {
        my ( $self, %args ) = @_;

        # TODO: writeme
    }

=head2 Test [PARAMS, Checks => ARRAYREF, IncludeAll => 1]

Test the event described in the parameters against this condition, returning
true if matched, false otherwise, and appending details of the checks
performed to the I<Checks> array reference.

If additional parameters are supplied, they are run through B<Set> above
before the test is performed.

The I<IncludeAll> parameter, and the contents of the I<Checks> array
reference, are described in the documentation of the C<RT::FilterRule>
B<Match> method.

(TODO)

=cut

    sub Test {
        my $self = shift;

        # TODO: writeme
        return 0;
    }

=head2 TestSingleValue PARAMS, Check => VALUE

Test the event described in the parameters against this condition, returning
true if matched, false otherwise, where only the specific I<VALUE> is tested
against the event's I<From>/I<To>/I<Ticket>.

This is called internally by the B<Test> method for each of the value checks
in the condition.

(TODO)

=cut

    sub TestSingleValue {
        my $self = shift;

        # TODO: writeme
        return 0;
    }





=head2 Properties

Return the properties of this object as a hash reference, suitable for
serialising and storing.

=cut

    sub Properties {
        my $self = shift;
        return {
            'ConditionType' => $self->{'ConditionType'},
            'CustomField'   => $self->{'CustomField'},
            'Values'        => $self->{'Values'}
        };
    }
}

{

=head1 Internal package RT::FilterRule::Action

This package provides the C<RT::FilterRule::Action> class, which describes
an action to perform on a ticket after matching a rule.

Objects of this class are not stored directly in the database, but are
encoded within attributes of C<RT::FilterRule> objects.

=cut

    package RT::FilterRule::Action;

    use base 'RT::Base';

=head1 RT::FilterRule::Action METHODS

This class inherits from C<RT::Base>.

=cut

=head2 new $UserObj[, PARAMS...]

Construct and return a new object, given an C<RT::CurrentUser> object.  Any
other parameters are passed to B<Set> below.

=cut

    sub new {
        my ( $proto, $UserObj, @args ) = @_;
        my ( $class, $self );

        $class = ref($proto) || $proto;

        $self = {
            'ActionType'  => 'All',
            'CustomField' => 0,
            'Value'       => '',
            'Notify' => '',
            'Ticket'      => undef,
        };

        bless( $self, $class );

        $self->CurrentUser($UserObj);

        $self->Set(@args);

        return $self;
    }

=head2 Set Key => VALUE, ...

Set parameters of this action object.  The following parameters define the
action itself:

=over 15

=item B<ActionType>

The type of action, such as I<SetSubject>, I<SetQueue>, and so on - see the
C<RT::Extension::FilterRules> method B<ActionTypes>.

=item B<CustomField>

The custom field ID associated with this action, if applicable (such as
which custom field to set the value of)

=item B<Value>

The value associated with this action, if applicable, such as the queue to
move to, or the contents of an email to send

=item B<Notify>

The notification recipient associated with this action, if applicable, such
as a group ID or email address to send a message to

=back

The following parameters define the ticket being acted upon:

=over 

=item B<Ticket>

The ticket ID or C<RT::Ticket> object to match the condition against

=back

This method returns nothing.

(TODO)

=cut

    sub Set {
        my ( $self, %args ) = @_;

        # TODO: writeme
    }

=head2 Perform

Perform the action described by this object's parameters, returning
( I<$ok>, I<$message> ).

(TODO)

=cut

    sub Perform {
        my $self = shift;

        # TODO: writeme
        return 0;
    }

=head2 IsNotification

Return true if this action is of a type which sends a notification, false
otherwise.  This is used when carrying out actions to ensure that all other
ticket actions are performed first.

(TODO)

=cut

    sub IsNotification {
        my $self = shift;

        # TODO: writeme
        return 0;
    }

=head2 Properties

Return the properties of this object as a hash reference, suitable for
serialising and storing.

=cut

    sub Properties {
        my $self = shift;
        return {
            'ActionType'  => $self->{'ActionType'},
            'CustomField' => $self->{'CustomField'},
            'Value'       => $self->{'Value'},
            'Notify'      => $self->{'Notify'}
        };
    }
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
        $self->OrderByCols( { FIELD => 'SortOrder', ORDER => 'ASC' } );
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

=item B<id>

The numeric ID of this event

=item B<FilterRule>

The numeric ID of the filter rule which matched (also presented as an
C<RT::FilterRule> object via B<FilterRuleObj>)

=item B<Ticket>

The numeric ID of the ticket whose event matched this rule (also presented
as an C<RT::Ticket> object via B<TicketObj>)

=item B<Created>

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
