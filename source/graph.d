module source.graph;

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

    Node getNode(string name, string[string] attrsLayer1, string[string] attrsLayer2)
    {
        if (name in nodes) return nodes[name];
        Node n = new Node(name);
        nodes[name] = n;

        if (attrsLayer2) foreach(k,v; attrsLayer2) n.attr[k] = v;
        if (attrsLayer1) foreach(k,v; attrsLayer1) n.attr[k] = v;

        return n;
    }
};

class Edge : Node
{
    Node left;
    Node right;

    this(Node a, Node b, string[string] attrsLayer1, string[string] attrsLayer2)
    {
        left = a;
        right = b;
        if (attrsLayer2) foreach(k,v; attrsLayer2) attr[k] = v;
        if (attrsLayer1) foreach(k,v; attrsLayer1) attr[k] = v;
    }
};
