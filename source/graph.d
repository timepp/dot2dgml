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
