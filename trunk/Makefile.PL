# IMPORTANT: if you delete this file your app will not work as
# expected.  you have been warned
use inc::Module::Install;

name 'Kiddman';
all_from 'lib/Kiddman.pm';

requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::FormValidator';
requires 'Catalyst::Plugin::I18N';
requires 'Catalyst::Plugin::Params::Nested';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Runtime' => '5.7014';
requires 'Catalyst::View::TT';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
requires 'DateTime';
requires 'DBIx::Class';
requires 'DBIx::Class::TimeStamp';
requires 'File::Spec';
requires 'Moose';
requires 'MooseX::Types';
requires 'parent';
requires 'Tree::Simple';
requires 'Tree::Simple::VisitorFactory';
requires 'YAML::XS';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
