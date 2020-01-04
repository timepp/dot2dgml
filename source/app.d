import std.stdio;
import std.getopt;

import source.graph;
import source.dot;
import source.dgml;
import source.strutil;

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
    Graph g = parseDot(content);
    string dgml = GenerateDgml(g);
    fo.writeln(dgml);
    return 0;
}
