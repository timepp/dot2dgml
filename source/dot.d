module source.dot;

import std.regex;
import std.string;
import std.stdio;

import source.graph;
import source.strutil;

// lookup next token in string, 
private string lookupToken(string s, ref int p)
{
    if (s.length == 0)
        return s;

    char ch = s[0];

    // spaces (Semicolons and commas aid readability but are not required.)
    if (indexOf(" \t\r\n,;", ch) >= 0)
    {
        p = 1;
        while (p < s.length && indexOf(" \t\r\n,;", s[p]) >= 0)
            p++;
        return "";
    }

    // quoted string
    if (ch == '"')
    {
        p = 1;
        while (p < s.length && !(s[p] == '"' && s[p - 1] != '\\'))
            p++;
        if (p < s.length)
            p++;
        return s[1 .. p - 1];
    }

    // line coment
    if (ch == '/' && s.length > 1 && s[1] == '/')
    {
        p = 2;
        while (p < s.length && s[p] != '\r' && s[p] != '\n')
            p++;
        // note: we are not eating the whole line comment but leave the newlines as is
        //       this is in DOT format because the next round of lookup will consume newlines as spaces
        //       which has no effect as well
        return "";
    }

    // block comment
    if (ch == '/' && s.length > 1 && s[1] == '*')
    {
        p = 2;
        while (p < s.length && !(s[p] == '/' && s[p - 1] == '*'))
            p++;
        if (p < s.length)
            p++;
        return "";
    }

    // ID
    if (indexOf("->{}=[]() \t\r\n/", ch) < 0)
    {
        p = 1;
        while (p < s.length && indexOf("->{}=[]() \t\r\n/", s[p]) < 0) p++;
        return s[0..p];
    }

    // others
    p = 1;
    return s[0..p];
}

/// Tokenize the source buffer to tokens, removing any comments and white spaces not inside string
string[] Tokenize(string s)
{
    string[] ret;
    while (s.length > 0)
    {
        int pos = 0;
        string token = lookupToken(s, pos);
        s = s[pos..$];
        if (token.length > 0) ret ~= token;
    }
    return ret;
}

unittest
{
    assert(Tokenize(`abc`) == [`abc`]);
    assert(Tokenize(` abc `) == [`abc`]);
    assert(Tokenize(`"abc"`) == [`abc`]);
    assert(Tokenize(` "abc" `) == [`abc`]);
    assert(Tokenize(` abc def `) == [`abc`, `def`]);
    assert(Tokenize(` "abc def" `) == [`abc def`]);
    assert(Tokenize(" \"@atrhelper//:atrhelper\" \n def") == [
            `@atrhelper//:atrhelper`, `def`
            ]);
}

Graph parseDot(string content)
{
    auto t = Tokenize(content);
    return ParseDot(t);
}

Graph ParseDot(string[] tokens)
{
    Graph g = new Graph;
    int p = 0;
    Node lastNode = null;
    while (p < tokens.length)
    {
        // graph header
        if (tokens[p].toLower() == "digraph")
        {
            for (; p < tokens.length && tokens[p] != "{"; p++)
            {
            }
            continue;
        }

        // graph attributes
        if (p > 0 && tokens[p] == "=" && p + 1 < tokens.length)
        {
            g.attr[tokens[p - 1]] = tokens[p + 1];
            p += 2;
            continue;
        }

        // edges
        if (p > 0 && p + 2 < tokens.length && tokens[p] == "-" && tokens[p + 1] == ">")
        {
            string leftName = tokens[p - 1].unquote();
            string rightName = tokens[p + 2].unquote();
            Node left = g.getNode(leftName);
            Node right = g.getNode(rightName);
            Edge e = new Edge(left, right);
            g.edges ~= e;
            lastNode = e;
            p += 3;
            continue;
        }

        // attributes
        if (tokens[p] == "[")
        {
            for (p++; p < tokens.length && tokens[p] != "]"; p++)
            {
                if (tokens[p] == "=" && p + 1 < tokens.length)
                {
                    if (lastNode)
                        lastNode.attr[tokens[p - 1]] = tokens[p + 1];
                }
            }
            p++;
            continue;
        }

        // normal nodes
        lastNode = g.getNode(tokens[p].unquote());
        p++;
    }

    return g;
}
