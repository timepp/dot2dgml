module strutil;

import std.string;
import std.algorithm;


int getIndention(string str)
{
    int indention = 0;
    while (indention < str.length && str[indention] == ' ')
    {
        indention++;
    }
    return indention;
}

unittest
{
    assert(getIndention("") == 0);
    assert(getIndention("    abcd f") == 4);
    assert(getIndention("abcd    ") == 0);
    assert(getIndention(" ") == 1);
    assert(getIndention("\tabcd") == 0);
}

/// unindent according to the first non-empty line
/// all empty lines before the first non-empty line will be removed
string unindent(string str)
{
    string ret;
    string[] lines = str.splitLines(KeepTerminator.yes);
    int indention = -1;
    foreach(l; lines)
    {
        if (indention == -1 && l.length > 0 && l[0] != '\r' && l[0] != '\n')
        {
            indention = l.getIndention();
        }

        if (indention != -1)
        {
            ret ~= l[min(indention,l.getIndention())..$];
        }
    }
    return ret;
}

unittest
{
    string src = `
        
        abcd
          efgh
         iikk
        `;
    immutable string dst = `
abcd
  efgh
 iikk
`;
    assert(src.unindent() == dst);
}
