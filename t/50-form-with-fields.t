#!/usr/bin/perl -w

# file 50-form3.t
use strict;


use WWW::Mechanize::WebDriver;
use lib 'inc', '../inc';
use Test::HTTP::LocalServer;
use Test::More;

my $mech = eval { WWW::Mechanize::WebDriver->new( 
    autodie => 1,
    launch_exe => 'phantomjs-versions\phantomjs-1.9.2-windows\phantomjs',
    launch_arg => ['ghostdriver\src\main.js' ],
    port => 8910, # XXX
    #log => [qw[debug]],
    #on_event => 1,
)};

if (! $mech) {
    plan skip_all => "Couldn't connect to PhantomJS: $@";
    exit
} else {
    plan tests => 8;
};

$mech->get_local('50-form3.html');
$mech->form_number(1);
my $the_form_dom_node = $mech->current_form;
my $button = $mech->selector('#btn_ok', single => 1);
isa_ok $button, 'Selenium::Remote::WebElement', "The button image";

ok $mech->submit, 'Sent the page';

$mech->get_local('50-form3.html');
@{$mech->{event_log}} = ();
$mech->form_id('snd');
if(! ok $mech->current_form, "We can find a form by its id") {
    for (@{$mech->{event_log}}) {
        diag $_
    };
};

$mech->get_local('50-form3.html');
$mech->form_with_fields('r1[name]');
ok $mech->current_form, "We can find a form by its contained input fields (single,matched)";

$mech->get_local('50-form3.html');
$mech->form_with_fields('r1[name]','r2[name]');
ok $mech->current_form, "We can find a form by its contained input fields (double,matched)";

$mech->get_local('50-form3.html');
$mech->form_with_fields('r3name]');
ok $mech->current_form, "We can find a form by its contained input fields (single,closing)";

$mech->get_local('50-form3.html');
$mech->form_with_fields('r4[name');
ok $mech->current_form, "We can find a form by its contained input fields (single,opening)";

$mech->get_local('50-form3.html');
$mech->form_name('snd');
ok $mech->current_form, "We can find a form by its name";

# Check that refcounting works and releases the bridge once we release
# our $mech instance
my $destroyed;
my $old_DESTROY = \&MozRepl::RemoteObject::DESTROY;
{ no warnings 'redefine';
   *MozRepl::RemoteObject::DESTROY = sub {
       $destroyed++;
       goto $old_DESTROY;
   }
};
