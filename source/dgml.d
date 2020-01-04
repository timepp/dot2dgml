module source.dgml;

import std.xml;
import std.string;

import source.graph;

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
        // FIXME: dgml uses `&#xD;&#xA` to represent new lines. Still hasn't figured out how to 
        //        output these strings using std.xml. 
        xn.attr["Label"] = n.id.replace("\\n", "__NEWLINE__");
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

    return join(doc.pretty(4), "\n").replace("__NEWLINE__", "&#xD;&#xA;");
}