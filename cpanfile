requires "base"                  => "0";
requires "Carp"                  => "0";
requires "Class::Accessor::Fast" => "0";
requires "Data::Dump"            => "0";
requires "Digest::MD5"           => "0";
requires "Hook::LexWrap"         => "0";
requires "Path::Tiny"            => "0";
requires "Scalar::Util"          => "0";
requires "strict"                => "0";
requires "version"               => "0";
requires "warnings"              => "0";

on test => sub {
    requires "Test::More"      => "0";
    requires "Test::Requires"  => "0";
    recommends "Capture::Tiny" => "0";
};

