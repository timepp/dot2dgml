import std.stdio;
import core.stdc.ctype;
import std.xml;
import std.string;
import std.getopt;
import std.conv;
import std.regex;

class Node
{
    dstring id;
    dstring[dstring] attr;
    this(dstring s)
    {
        id = s;
    }
    this()
    {
    }
};

class Graph : Node
{
    Node[dstring] nodes;
    Edge[] edges;

    Node getNode(dstring name)
    {
        if (name in nodes) return nodes[name];
        Node n = new Node(name);
        nodes[name] = n;
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
dstring[] Tokenize(dstring s)
{
	// Remove quote, if any
	s = strip(s);
	if (s[0] == '"') s = s[1..$-1];

	// Remove comments
	s = replace(s, regex(r"/\*.*?\*/"d, "gs"), " "d);
	s = replace(s, regex(r"//.*?\n"d, "g"), "\n"d);

    dstring[] ret;
    bool inString = false;
    int p = 0;
    int q = 0;
    for (;;)
    {
        if (q == s.length)
        {
			if (p < q) ret ~= s[p..q];
            break;
        }

        dchar ch = s[q];
        dchar ch2 = (q+1 == s.length)? 0 : s[q+1];
        if (inString)
        {
            if (ch == '"')
            {
                inString = false;
            }
            q++;
        }
        else
        {
            if (ch == '"')
            {
                q++;
                inString = true;
            }
			else if (indexOf("->{}=[]()"d, ch) != -1)
			{
				if (p < q) ret ~= s[p..q];
				ret ~= s[q..q+1];
				p = q+1;
				q++;
			}
			else if (indexOf(" \t\r\n;"d, ch) != -1)
			{
				if (p < q) ret ~= s[p..q];
				p = q+1;
				q++;
			}
			else
            {
                q++;
            }
        }
    }

    return ret;
}

dstring normalize(dstring s)
{
    if (s.length > 1 && s[0] == '"' && s[$-1] == '"')
    {
        s = s[1..$-1];
    }

    return s.strip();
}

Graph ParseDot(dstring[] tokens)
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
            g.attr[tokens[p-1]] = tokens[p+1];
            p += 2;
            continue;
        }

        // edges
        if (p > 0 && p + 2 < tokens.length && tokens[p] == "-" && tokens[p+1] == ">")
        {
            dstring leftName = tokens[p-1].normalize();
            dstring rightName = tokens[p+2].normalize();
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

dstring MapAttribute(dstring attr)
{
	if (attr == "color"d) return "Stroke"d;
	if (attr == "fillcolor"d) return "Background"d;
	if (attr == "fontcolor"d) return "Foreground"d;
	return attr;
}

string GenerateDgml(Graph g)
{
    auto xg = new Tag("DirectedGraph");
    xg.attr["xmlns"] = "http://schemas.microsoft.com/vs/2009/dgml";
    auto doc = new Document(xg);

    auto xNodes = new Element("Nodes");
    foreach(dstring nodeID, Node n; g.nodes)
    {
        auto xn = new Tag("Node");
        xn.attr["Id"] = to!string(nodeID);
        xn.attr["Label"] = to!string(n.id);
        foreach(dstring k, dstring v; n.attr)
        {
           xn.attr[to!string(MapAttribute(k))] = to!string(v);
        }
        xNodes ~= new Element(xn);
    }
    doc ~= xNodes;

    auto xEdges = new Element("Links");
    foreach(e; g.edges)
    {
        auto xe = new Tag("Link");
        xe.attr["Target"] = to!string(e.right.id);
        xe.attr["Source"] = to!string(e.left.id);
        foreach(dstring k, dstring v; e.attr)
        {
            xe.attr[to!string(MapAttribute(k))] = to!string(v);
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

	string content = fi.readln(0);
	dstring dstr = to!dstring(content);
	dstring[] tokens = Tokenize(dstr);
    Graph g = ParseDot(tokens);
    string dgml = GenerateDgml(g);
    fo.writeln(dgml);
    return 0;
}
