module pap.recipes.project;

import pap.util.mapper;

public struct ProjectRecipe
{
    @Field("name")
    @Required
    string name;

    @Field("version")
    string version_;

    @Field("language")
    string language; // ?

    @Field("author")
    string author;

    @Field("license")
    string license;

    @Field("include")
    string[] includes;
}

public bool validate(ProjectRecipe recipe)
{
    return true;
}
