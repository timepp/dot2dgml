dot2dgml
========

Convert from [graphviz dot digraph][dot] to [microsoft dgml format][dgml].

[dot]:  http://www.graphviz.org/content/dot-language
[dgml]: http://msdn.microsoft.com/en-us/vstudio/gg145498

Graphviz dot invents the *simplest style for modeling dependencies*. But output
formats are all static -- it's hard to do further processing on them.
On the contrast, Microsoft Visual Studio has great support on dgml file format
(another language for directed graph).  You can easily view and edit the
dependencies (drag, assign color, re-layout...) in Visual Studio.

dot2dgml is the tool to translate the easy-to-write dot language to the
easy-to-view dgml language. So your idea can start up from scratch easily.

features & limitations
======================

dot2dgml do loose syntax check on dot language to minimize the required steps
to dgml:

* the `graph` statement can be ommited.
* minor syntax errors will be ignored.

the shortest valid non-trival input is:

	a->b

dot2dgml has limitations as well:

* many dot language features are not available in dgml.
* sub-graph is not supported as for now.

download
========

You can download it at [github](https://github.com/timepp/dot2dgml/releases).


examples
========

The following command:

	echo -n "a->b->c b->d" | dot2dgml -o abcd.dgml

will produce `abcd.dgml` with following content:

```XML
<DirectedGraph xmlns="http://schemas.microsoft.com/vs/2009/dgml">
<Nodes>
    <Node Label="d" Id="d" />
    <Node Label="a" Id="a" />
    <Node Label="b" Id="b" />
    <Node Label="c" Id="c" />
</Nodes>
<Links>
    <Link Target="b" Source="a" />
    <Link Target="c" Source="b" />
    <Link Target="d" Source="b" />
</Links>
</DirectedGraph>
```

Open `abcd.dgml` with visual studio, you will see something like this:

![abcd dgml at visual studio](http://timepp.github.io/product/dot2dgml/abcd_dgml_in_visual_studio.png)

Then you can drag/colorize/group/flag... in the rich featured editor. Enjoy!!!

More examples:

    BCPL [fillcolor=#008000;fontcolor=#ffff00] BCPL->B->C C->C++ [color=red] Simula->C++ [color=red]
![C++ dependencies](http://timepp.github.io/product/dot2dgml/cplusplus_dgml.png)
