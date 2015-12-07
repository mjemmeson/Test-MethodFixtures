requires "base";
requires "Carp";
requires "Class::Accessor::Fast";
requires "Hook::LexWrap";
requires "Scalar::Util";
requires "strict";
requires "version";
requires "warnings";

recommends "Data::Dump";
recommends "Digest::MD5";
recommends "Path::Tiny";

on test => sub {
    requires "Digest::MD5";
    requires "File::Temp";
    requires "File::Temp";
    requires "Storable";
    requires "Test::Exception";
    requires "Test::More";
    requires "Test::Requires";
};

on develop => sub {
    recommends "Dist::Milla";
    recommends "Dist::Zilla::Plugin::MetaProvides";
};
