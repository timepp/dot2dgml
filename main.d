import std.stdio;
import core.stdc.ctype;
import std.xml;
import std.string;
import std.getopt;

class Node
{
    string id;
    string[string] attr;
    this(string s)
    {
        id = s;
    }
    this()
    {
    }
};

class Graph : Node
{
    Node[string] nodes;
    Edge[] edges;

    Node getNode(string name)
    {
        auto key = name.toLower();
        if (key in nodes) return nodes[key];
        Node n = new Node(name);
        nodes[key] = n;
        return n;
    }
};

class Edge : Node
{
    Node left;
    Node right;

    this(Node a, Node b)
    {
        left = a;
        right = b;
    }
};

// Tokenize the source buffer to tokens, removing any comments and white spaces not inside string
string[] Tokenize(string s)
{
    string[] ret;
    bool inString = false;
    bool inBlockComment = false;
    bool inLineComment = false;
    int p = 0;
    int q = 0;
    for (;;)
    {
        if (q == s.length)
        {
            if (!inBlockComment && !inLineComment)
            {
                if (p < q) ret ~= s[p..q];
            }
            break;
        }

        char ch = s[q];
        char ch2 = (q+1 == s.length)? 0 : s[q+1];
        if (inString)
        {
            if (ch == '"')
            {
                inString = false;
            }
            q++;
        }
        else if (inBlockComment)
        {
            if (ch == '*' && ch2 == '/')
            {
                q += 2;
                p = q;
                inBlockComment = false;
            }
            else
            {
                q++;
            }
        }
        else if (inLineComment)
        {
            if (ch == '\r' || ch == '\n')
            {
                q++;
                p = q;
                inLineComment = false;
            }
            else
            {
                q++;
            }
        }
        else
        {
            if (isalnum(ch) || ch == '_' || ch == '.')
            {
                q++;
            }
            else if (ch == '"')
            {
                q++;
                inString = true;
            }
            else if (ch == '/' && ch2 == '/')
            {
                if (p < q) ret ~= s[p..q];
                q++;
                inLineComment = true;
            }
            else if (ch == '/' && ch2 == '*')
            {
                if (p < q) ret ~= s[p..q];
                q++;
                inBlockComment = true;
            }
            else
            {
                if (p < q) ret ~= s[p..q];
                if (ch != ' ' && ch != '\t' && ch != '\r' && ch != '\n' && ch != ';')
                {
                    ret ~= s[q..q+1];
                }
                p = q+1;
                q++;
            }
        }
    }

    return ret;
}

string normalize(string s)
{
    if (s.length > 1 && s[0] == '"' && s[$-1] == '"')
    {
        s = s[1..$-1];
    }

    return s.strip();
}

Graph ParseDot(string dotsrc)
{
    string[] tokens = Tokenize(dotsrc);
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
            g.attr[tokens[p-1]] = tokens[p+1];
            p += 2;
            continue;
        }

        // edges
        if (p > 0 && p + 2 < tokens.length && tokens[p] == "-" && tokens[p+1] == ">")
        {
            string leftName = tokens[p-1].normalize();
            string rightName = tokens[p+2].normalize();
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
                if (tokens[p] == "=" && p+1 < tokens.length)
                {
                    if (lastNode) lastNode.attr[tokens[p-1]] = tokens[p+1];
                }
            }
            p++;
            continue;
        }

        // normal nodes
        if (isalnum(tokens[p][0]))
        {
            lastNode = g.getNode(tokens[p].normalize());
            p++;
            continue;
        }

        // others, ignore
        p++;
    }

    return g;
}

string GenerateDgml(Graph g)
{
    auto xg = new Tag("DirectedGraph");
    xg.attr["xmlns"] = "http://schemas.microsoft.com/vs/2009/dgml";
    auto doc = new Document(xg);

    auto xNodes = new Element("Nodes");
    foreach(string nodeID, Node n; g.nodes)
    {
        auto xn = new Tag("Node");
        xn.attr["Id"] = nodeID;
        xn.attr["Label"] = n.id;
        foreach(string k, string v; n.attr)
        {
            xn.attr[k] = v;
        }
        xNodes ~= new Element(xn);
    }
    doc ~= xNodes;

    auto xEdges = new Element("Links");
    foreach(e; g.edges)
    {
        auto xe = new Tag("Link");
        xe.attr["Target"] = e.right.id;
        xe.attr["Source"] = e.left.id;
        foreach(string k, string v; e.attr)
        {
            xe.attr[k] = v;
        }
        xEdges ~= new Element(xe);
    }
    doc ~= xEdges;

    return join(doc.pretty(4), "\n");
}

int main(string[] args)
{
    bool showHelp = false;
    string outfile;
    getopt(args, "help|h", &showHelp, "output|o", &outfile);
    if (showHelp)
    {
        writeln("dot2dgml 1.0: convert dot files to dgml. \n"
                "the dgml files can be viewed by Microsoft Visual Studio. \n\n"
                "Usage: dot2dgml [dot file] [-o|--output dgml file]\n"
                "\n"
                "if dot file is ommited, dot2dgml will read from input\n"
                "if dgml file is ommited, dot2dgml will write to output\n"
                "\n"
                "\n"
                "https://github.com/timepp/script"
                );
        return 0;
    }

    // default to read input and write output
    File fi = stdin;
    File fo = stdout;

    if (args.length > 1)
    {
        fi = File(args[1], "r");
    }
    if (outfile.length > 0)
    {
        fo = File(outfile, "w");
    }

    Graph g = ParseDot(fi.readln(0));
    string dgml = GenerateDgml(g);
    fo.writeln(dgml);
    return 0;
}
