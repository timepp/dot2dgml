import std.stdio;
import core.stdc.ctype;
import std.xml;
import std.string;
import std.getopt;
import std.conv;
import std.regex;

import strutil;

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
string[] Tokenize(string s)
{
	// Remove quote, if any
	s = strip(s);
	if (s[0] == '"') s = s[1..$-1];

	// Remove comments
	s = replace(s, regex(r"/\*.*?\*/", "gs"), " ");
	s = replace(s, regex(r"//.*?\n", "g"), "\n");

    string[] ret;
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
			else if (indexOf("->{}=[]()", ch) != -1)
			{
				if (p < q) ret ~= s[p..q];
				ret ~= s[q..q+1];
				p = q+1;
				q++;
			}
			else if (indexOf(" \t\r\n;", ch) != -1)
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

string normalize(string s)
{
    if (s.length > 1 && s[0] == '"' && s[$-1] == '"')
    {
        s = s[1..$-1];
    }

    return s.strip();
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
        lastNode = g.getNode(tokens[p].normalize());
		writeln(lastNode.id);
        p++;
    }

    return g;
}

string MapAttribute(string attr)
{
	if (attr == "color") return "Stroke";
	if (attr == "fillcolor") return "Background";
	if (attr == "fontcolor") return "Foreground";
	return attr;
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
           xn.attr[MapAttribute(k)] = v;
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
            xe.attr[MapAttribute(k)] = v;
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
        writeln(unindent(`
            dot2dgml 1.0: convert dot files to dgml. 
            the dgml files can be viewed by Microsoft Visual Studio. 

            Usage: dot2dgml [dot file] [-o|--output dgml file]

            if dot file is ommited, dot2dgml will read from input
            if dgml file is ommited, dot2dgml will write to output
			`));
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
	string[] tokens = Tokenize(content);
	writeln(tokens);
    Graph g = ParseDot(tokens);
    string dgml = GenerateDgml(g);
    fo.writeln(dgml);
    return 0;
}
