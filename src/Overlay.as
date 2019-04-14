package {
    import flash.display.MovieClip;
    import flash.geom.Point;

    import generation.Civilization;
    import generation.Geography;

    import mx.core.UIComponent;
    import mx.events.FlexEvent;

    public class Overlay extends UIComponent {
        public var map:Map;
        public var overlay:MovieClip;

        private var geo:Geography;
        private var civ:Civilization;

        public function Overlay() {
            geo = Geography.getInstance();
            civ = Civilization.getInstance();

            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(event:FlexEvent):void {
            overlay = new MovieClip();
            addChild(overlay);
        }

        public function validate():void {
            x = map.x;
            y = map.y;
        }

        public function drawLabels():void {
            // Clear old labels
            overlay.graphics.clear();
            while (overlay.numChildren > 0)
                overlay.removeChildAt(0);

            // Draw new labels
            labelLands();
            labelRegions();
        }

        private function labelLands():void {
            for each (var land:Object in geo.getFeaturesByType(Geography.LAND)) {
                var point:Point = land.centroid;
                var label:LandLabel = new LandLabel(land);
                overlay.addChild(label);
                label.x = point.x;
                label.y = point.y;
            }
        }

        private function labelRegions():void {
        }
    }
}