package {
import flash.display.Sprite;

import mx.core.UIComponent;

import net.ivank.voronoi.*;

import flash.geom.Point;

public class HeightMap extends UIComponent {
    public function HeightMap() {
        var i:int;
        var edges:Vector.< VEdge >;       // vector for edges
        var v:Voronoi = new Voronoi();    // this instance will compute the diagram
        // vector for sites, for which we compute a diagram
        var vertices:Vector.< Point> = new Vector.< Point >();

        // let's add some random sites
        for (i = 0; i < 20; i++) {
            var p = new Point(Math.random() * 1000, Math.random() * 800)
            vertices.push(p);
        }
        // call a method which computes a diagram, width and height limit
        edges = v.GetEdges(vertices, 1000, 800);

        // drawing a Delaunay triangulation
        graphics.lineStyle(3, 0x888888);
        for (i = 0; i < edges.length; i++) {
            graphics.moveTo(edges[i].left.x, edges[i].left.y);
            graphics.lineTo(edges[i].right.x, edges[i].right.y);
        }

        // drawing a Voronoi diagram
        graphics.lineStyle(5, 0x000000);
        for (i = 0; i < edges.length; i++) {
            graphics.moveTo(edges[i].start.x, edges[i].start.y);
            graphics.lineTo(edges[i].end.x, edges[i].end.y);
        }
    }
}
}
