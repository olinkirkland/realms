package graph {
    import flash.geom.Point;

    public class Corner {
        public var index:int;

        // Centerline Labeling (and other uses)
        public var used:Boolean;
        public var costSoFar:Number;
        public var cameFrom:Corner;
        public var priority:Number;

        // Location
        public var point:Point;

        // A set of polygons touching this corne
        public var touches:Vector.<Cell>;

        // A set of edges touching the corner
        public var protrudes:Vector.<Edge>;

        // A set of corners connected to this one
        public var adjacent:Vector.<Corner>;

        // Is it at the edge of the map?
        public var border:Boolean;

        // Elevation
        public var elevation:Number;

        public function Corner() {
            touches = new Vector.<Cell>();
            protrudes = new Vector.<Edge>();
            adjacent = new Vector.<Corner>();
        }
    }
}
