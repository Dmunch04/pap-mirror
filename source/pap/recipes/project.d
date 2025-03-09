module pap.recipes.project;

import ymlmap;

public struct ProjectRecipe
{
    /// The name of the project
    @Field("name")
    @Required
    string name;

    /// The version of the project
    @Field("version")
    string version_;

    /// The programming language of the project (currently unused)
    @Field("language")
    string language; // ?

    /// The author of the language
    @Field("author")
    string author;

    /// The license type of the project
    @Field("license")
    string license;

    /// List of paths to separate yaml files, from which to include the `stages` object from
    @Field("include")
    string[] includes;
}

/++
 + Validate the project recipe.
 + Returns `true` if no errors found, otherwise `false`.
 +/
public bool validate(ProjectRecipe recipe)
{
    return true;
}
