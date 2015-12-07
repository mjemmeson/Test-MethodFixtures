requires "base"                  => "0";
requires "Carp"                  => "0";
requires "Class::Accessor::Fast" => "0";
requires "Hook::LexWrap"         => "0";
requires "Scalar::Util"          => "0";
requires "strict"                => "0";
requires "version"               => "0";
requires "warnings"              => "0";

recommends "Data::Dump"  => "0";
recommends "Digest::MD5" => "0";
recommends "Path::Tiny"  => "0";

on test => sub {
    requires "Digest::MD5"     => "0";
    requires "File::Temp"      => "0";
    requires "Storable"        => "0";
    requires "Test::More"      => "0";
    requires "Test::Exception" => "0";
    requires "File::Temp"      => "0";
    recommends "Test::Output" => "0";
};

on develop => sub {
    recommends "Dist::Milla"                       => "0";
    recommends "Dist::Zilla::Plugin::MetaProvides" => "0";
};
