module pap.util.formatter;

import std.array : split, replace;
import std.algorithm : canFind;
import std.process : environment;
import std.regex : ctRegex, matchAll, matchFirst;
import std.string : strip;

auto rxFormattable = ctRegex!(`\$\{\{([a-zA-Z0-9._ ]+)\}\}`, "gm");
auto rxString = ctRegex!(`[a-zA-Z0-9._ ]+`, "gm");

/++
 + Checks whether a string needs formatting.
 + The string needs formatting if it contains a variable in the format `${{ type.VARIABLE }}`.
 +/
public bool needsFormatting(string s)
{
    return !matchFirst(s, rxFormattable).empty;
}

/++
 + Formats a string with the given values.
 + The string can contain variables in the format `${{ type.VARIABLE }}`.
 + If the variable is not found in the values, it will try to get it from the environment.
 +/
public string format(string s, string[string] values)
in (needsFormatting(s))
out (r; !needsFormatting(r))
{
    import std.stdio : writeln;

    auto matches = matchAll(s, rxFormattable);
    if (matches.empty)
        return s;

    string formattedString = s;
    string result = matches.hit;
    while (result)
    {
        string variable = matchFirst(result, rxString).hit;
        
        string[] parts = variable.strip.split(".");
        assert(parts.length == 2, "Invalid variable format.");
        
        string type = parts[0];
        switch (type)
        {
            case "env":
                string key = parts[1];
                string value;
                if (key in values)
                    value = values[key];
                else
                    value = environment.get(key, null);

                if (value is null || value == "")
                {
                    writeln("Warning: Environment variable ", key, " not found.");
                    value = "";
                }

                formattedString = formattedString.replace(result, value);
                break;

            default:
                assert(0, "Invalid variable key '" ~ type ~ "'");
        }

        matches.popFront();
        if (matches.empty)
            break;

        result = matches.hit;
    }

    return formattedString;
}
