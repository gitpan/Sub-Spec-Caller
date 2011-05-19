
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Call subroutines',
  'dist_author' => [
    'Steven Haryanto <stevenharyanto@gmail.com>'
  ],
  'dist_name' => 'Sub-Spec-Caller',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'Sub::Spec::Caller',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Array::Find' => '0',
    'Data::Rmap' => '0',
    'DateTime' => '0',
    'Sub::Spec' => '0.13',
    'Test::More' => '0.96',
    'perl' => '5.010000'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
