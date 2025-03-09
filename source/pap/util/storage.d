module pop.util.storage;

import std.process : environment;
import std.path : buildPath;

/*
version(Windows) package string persistentStoragePath = buildPath(environment.get("LOCALAPPDATA"), "pap");
else version(linux) package string persistentStoragePath = buildPath(environment.get("HOME"), ".local", "share", "pap");
else version(OSX) package string persistentStoragePath = buildPath(environment.get("HOME"), "Library", "Application Support", "pap");
else package string persistentStoragePath = null;
*/
