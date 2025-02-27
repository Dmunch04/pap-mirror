/**
 * Acknowledgements:
 * This file uses elements and techniques heavily inspired by the cli-d package by Sebastiaan de Schaetzen.
 * The code can by found at https://github.com/seeseemelk/cli-d
 */

/++
 + This module provides a way to map a YAML node from DYAML to a struct.
 + Struct fields must be annotated with the `Field` attribute to be recognized by the mapper.
 + Fields annotated with the `Required` attribute will be checked for existence.
 + If a required field is missing, the mapper will write errors to stderr.
 + 
 + In it's current state, the mapper might be a bit limiting, and unable to handle all types and edgecases.
 + Current known limitations:
 + - The mapper only supports mapping to associative arrays with string keys and values of scalar types (this includes strings).
 +   Any attempt at mapping to a struct or other complex types, will most likely throw errors.
 + - The `Field` annotation must explicitly specify the name of the field in the YAML file.
 +
 + Example:
 + ```
 + struct MyConfig
 + {
 +     @Field("name")
 +     @Required
 +     string name;
 +
 +     @Field("age")
 +     int age;
 + }
 +
 + void main()
 + {
 +     auto root = Loader.fromFile("config.yml").load();
 +     bool validated;
 +     auto config = map!MyConfig(root, validated);
 +     assert(validated, "Config validation failed");
 + }
 +/

module pap.util.mapper;

import std.stdio : stderr;
import std.typecons : Nullable;
import std.traits : hasUDA, getUDAs, hasMember, getSymbolsByUDA;
import std.meta : Alias, AliasSeq, anySatisfy;
import std.traits : isArray, isAssociativeArray, isIntegral, isFloatingPoint, isSomeString;
import std.datetime : SysTime;
import std.conv : to;

import dyaml;
import dyaml.stdsumtype;

/++
 + This attribute will mark a property as a field in the YAML file.
 +/
public struct Field
{
    /// The name of the field in the YAML file.
    public string name;

    /++
     + Constructor for the `Field` attribute.
     + Takes the name of the field, the way it should be presented in the YAML file.
     +/
    public this(string name)
    {
        this.name = name;
    }

    public bool equals(string arg) immutable
    {
        return name == arg;
    }
}

/++
 + This attribute will mark a property as a required field in the YAML file.
 +/
public struct Required
{
}

private struct ParseState(C)
{
    C c;
    Node root;
    bool failed;
    mixin RequireStruct!C requires;
}

private mixin template RequireStruct(C)
{
    static foreach (member; getSymbolsByUDA!(C, Required))
    {
        mixin("bool " ~ member.stringof ~ ";");
    }
}

private alias Value = SumType!(/*YAMLInvalid,*/ YAMLNull, /*YAMLMerge,*/ bool, long, real, ubyte[], SysTime, string, Node.Pair[], Node[]);

private enum isYamlType(T) = isIntegral!T || isFloatingPoint!T || isSomeString!T || is(typeof({ Value i = T.init; }));

/++
 + Recursively maps a YAML node to a struct.
 + The parameter `successfulValidation` will be `true` if the mapping was successful and all required fields were present.
 +/
public C map(C)(Node root, ref bool successfulValidation)
{
    validateStruct!C();
    C c;
    ParseState!C state = ParseState!C(c, root);

    if (root.type == NodeType.sequence)
    {
        foreach (Node node; root.sequence())
        {
            mapNode!(C)(state, c, node);
        }
    }
    else if (root.type == NodeType.mapping)
    {
        foreach (Node.Pair pair; root.mapping())
        {
            mapNode!(C)(state, c, Node(pair.value, pair.key.as!string));
        }
    }

    bool validated = checkRequires(state, root);
    successfulValidation = state.failed ? false : validated;

    return c;
}

private void mapNode(C)(ref ParseState!C state, ref C c, Node node)
{
    foreach (member; __traits(allMembers, C))
    {
        static if (hasUDA!(__traits(getMember, c, member), Field))
        {
            if (getUDAs!(__traits(getMember, c, member), Field)[0].name == node.tag)
            {
                if (node.type == NodeType.sequence)
                {
                    static if (is(typeof(__traits(getMember, c, member)) : E[], E))
                    {
                        static if (is(E == struct))
                        {
                            auto arr = __traits(getMember, c, member);
                            int i;
                            foreach (Node element; node.sequence())
                            {
                                bool validated = false;
                                element = Node(element, node.tag ~ "." ~ i.to!string);
                                auto value = map!E(element, validated);
                                //if (!validated) return;
                                if (!validated) state.failed = true;
                                arr ~= value;
                                i++;
                            }

                            __traits(getMember, c, member) = arr;

                            static if (hasUDAV!(C, member, Required))
                            {
                                mixin("state.requires." ~ member ~ " = true;");
                            }
                        }
                        else static if (isYamlType!E)
                        {
                            auto arr = __traits(getMember, c, member);
                            foreach (Node element; node.sequence())
                            {
                                arr ~= element.as!E;
                            }

                            __traits(getMember, c, member) = arr;

                            static if (hasUDAV!(C, member, Required))
                            {
                                mixin("state.requires." ~ member ~ " = true;");
                            }
                        }
                    }
                }
                else if (node.type == NodeType.mapping)
                {
                    static if (is(typeof(__traits(getMember, c, member)) == struct))
                    {
                        bool validated = false;
                        auto value = map!(typeof(__traits(getMember, c, member)))(node, validated);
                        //if (!validated) return;
                        if (!validated) state.failed = true;
                        __traits(getMember, c, member) = value;

                        static if (hasUDAV!(C, member, Required))
                        {
                            mixin("state.requires." ~ member ~ " = true;");
                        }

                        //__traits(getMember, c, member) = map!(typeof(__traits(getMember, c, member)))(node);
                    }
                    else static if (is(typeof(__traits(getMember, c, member)) : V[K], K, V))
                    {
                        static assert(isAssociativeArray!(typeof(__traits(getMember, c, member))));
                        static assert(isYamlType!K && isYamlType!V);

                        auto map = __traits(getMember, c, member);
                        foreach (Node.Pair pair; node.mapping())
                        {
                            map[pair.key.as!K] = pair.value.as!V;
                        }

                        __traits(getMember, c, member) = map;

                        static if (hasUDAV!(C, member, Required))
                        {
                            mixin("state.requires." ~ member ~ " = true;");
                        }
                    }
                }
                else
                {
                    static if (isYamlType!(typeof(__traits(getMember, c, member))))
                    {
                        __traits(getMember, c, member) = node.as!(typeof(__traits(getMember, c, member)));

                        static if (hasUDAV!(C, member, Required))
                        {
                            mixin("state.requires." ~ member ~ " = true;");
                        }
                    }
                }
            }
        }
    }
}

private bool checkRequires(C)(ref ParseState!C state, Node parent)
{
    bool failed = false;
    static foreach (member; __traits(allMembers, state.requires))
    {
        if (!mixin("state.requires." ~ member))
        {
            stderr.writeln("Required field '" ~ getUDAs!(value!(C, member), Field)[0].name ~ "' is missing from object '" ~ parent.tag ~ "'!");
            failed = true;
        }
    }

    return !failed;
}

private void validateStruct(C)()
{
    static assert(is(C == struct), "Configuration object must be a struct");
    static foreach (member; __traits(allMembers, C))
    {
        static if (!hasUDAV!(C, member, Field))
        {

        }
    }
}

private template value(C, alias m)
{
    alias value = __traits(getMember, C, m);
}

private template value(alias c, alias m)
{
    alias value = __traits(getMember, c, m);
}

private template hasUDAV(C, alias m, T)
{
    alias hasUDAV = hasUDA!(value!(C, m), T);
}

private template hasUDAV(C, alias m, alias t)
{
    alias hasUDAV = hasUDA!(value!(C, m), t);
}

private template hasUDAV(alias c, alias m, alias t)
{
    alias hasUDA = hasUDA!(value!(c, m), t);
}

private template hasField(alias E)
{
    alias hasField = hasUDA!(E, Field);
}

private template hasField(C, alias E)
{
    alias hasField = Alias!(hasUDA!(value!(C, E), Field));
}

private template getField(alias E)
{
    alias getField = Alias!(getUDAs!(E, Field)[0]);
}

private template getField(C, alias e)
{
    alias getField = Alias!(getUDAs!(value!(C, e), Field)[0]);
}

private bool hasNamedField(C)(string name)
{
    static foreach (member; __traits(allMembers, C))
    {
        if (hasField!(C, member) && getField!(C, member).name == name)
        {
            return true;
        }
    }

    return false;
}

private template isRequired(alias E)
{
    alias isRequired = Alias!(hasUDA!(E, Required));
}

private template isRequired(C, alias e)
{
    alias isRequired = Alias!(isRequired!(value!(C, e)));
}

private template isNamedField(alias e)
{
    alias isNamedField = Alias!(getField!(e).name.length > 0);
}

private template isNamedField(alias C, alias e)
{
    alias isNamedField = isNamedField!(value!(C, e));
}

private template isUnnamedField(alias C, alias e)
{
    alias isUnnamedField = Alias!(hasField!(value!(C, e)) && !isNamedField!(C, e));
}

private template hasNamedFields(C, members...)
{
    static if (isNamedField!(C, members[0]))
    {
        alias hasNamedFields = Alias!true;
    }
    else static if (members.length == 1)
    {
        alias hasNamedFields = isNamedField!(C, members[0]);
    }
    else
    {
        alias hasNamedFields = hasNamedFields!(C, members[1..$]);
    }
}

private template hasNamedFields(C, member)
{
    alias hasNamedFields = isNamedField!(C, member[i]);
}

private alias hasNamedFields(C) = hasNamedFields!(C, __traits(allMembers, C));

private template hasUnnamedFields(C, members...)
{
    static if (!isNamedField!(C, members[0]))
    {
        alias hasUnnamedFields = Alias!true;
    }
    else static if (members.length == 1)
    {
        alias hasUnnamedFields =  Alias!(!isNamedField!(C, members[0]));
    }
    else
    {
        alias hasUnnamedFields = hasUnnamedFields!(C, members[1..$]);
    }
}

private alias hasUnnamedFields(C) = hasUnnamedFields!(C, __traits(allMembers, C));
