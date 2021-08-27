# NAME

RT::Extension::FilterRules - Filter incoming tickets through rule sets

# NOTE

There is no working code here yet; this is still being developed.

# DESCRIPTION

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

Filter rules are managed under _Tools_ - _Filter rules_.
