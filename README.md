CSS: /stylesheets/product.css
CSS: ../product.css
CSS: product.css

dot2dgml
========

Convert from [graphviz dot digraph][1] to [microsoft dgml format][2]

[1]: http://www.graphviz.org/content/dot-language
[2]: http://msdn.microsoft.com/en-us/vstudio/gg145498

motivation
==========

Graphviz dot language invents the simplest style for modeling dependencies.
But output formats of `dot` program are all static -- it's hard to do further
processing on them.  On the contrast, microsoft visual studio has great
support on dgml file format.  You can easily view and edit the dependencies (
drag, assign color, re-layout...).

dot2dgml is the tool to translate the easy-to-write dot language to
easy-to-view dgml language.

limitations
===========

dot2dgml input syntax is looser than dot language:

* the `graph` statement can be ommited.
  the shortest but non-trival input is:
		a->b

dot2dgml has some limitations as well:

* many dot language features are not available in dgml
* sub-graph is not supported as for now

examples
========

the following command:

	echo -n "a->b->c b->d" | dot2dgml -o abcd.dgml

will produce `abcd.dgml` with following content:

```CSS
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

open `abcd.dgml` with visual studio, you will see something like this:

![abcd dgml at visual studio](http://timepp.github.io/product/dot2dgml/abcd_dgml_in_visual_studio.png)

