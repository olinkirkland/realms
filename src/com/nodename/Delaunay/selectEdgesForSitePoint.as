package com.nodename.Delaunay
{
	import flash.geom.Point;
	
	internal function selectEdgesForSitePoint(coord:Point, edgesToTest:Vector.<Edge>):Vector.<Edge>
	{
		return edgesToTest.filter(myTest);
		
		function myTest(edge:Edge):Boolean
		{
			return ((edge.leftSite && edge.leftSite.coord == coord)
			||  (edge.rightSite && edge.rightSite.coord == coord));
		}
	}
}