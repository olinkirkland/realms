package {
    import assets.icons.Icons;

    import flash.display.MovieClip;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import generation.City;
    import generation.Civilization;
    import generation.Geography;
    import generation.towns.Town;

    import labels.CityLabel;

    import labels.IconLabel;
    import labels.LandLabel;
    import labels.MapLabel;
    import labels.RegionLabel;

    import mx.core.UIComponent;
    import mx.events.FlexEvent;

    public class Overlay extends UIComponent {
        public var map:Map;
        public var regionLabelsLayer:MovieClip;
        public var citiesAndTownsLayer:MovieClip;

        private var geo:Geography;
        private var civ:Civilization;

        public function Overlay() {
            geo = Geography.getInstance();
            civ = Civilization.getInstance();

            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }

        private function onCreationComplete(event:FlexEvent):void {
            citiesAndTownsLayer = new MovieClip();
            addChild(citiesAndTownsLayer);
            regionLabelsLayer = new MovieClip();
            addChild(regionLabelsLayer);
        }

        public function validate():void {
            x = map.x;
            y = map.y;
        }

        public function drawLabels():void {
            // Clear old labels
            regionLabelsLayer.graphics.clear();
            while (regionLabelsLayer.numChildren > 0)
                regionLabelsLayer.removeChildAt(0);

            // Clear old icons
            citiesAndTownsLayer.graphics.clear();
            while (citiesAndTownsLayer.numChildren > 0)
                citiesAndTownsLayer.removeChildAt(0);

            // Draw new labels
            labelRegions();
            //labelCitiesAndTowns();

            // Position labels
            positionLabels(1);
        }

        public function positionLabels(scale:Number):void {
            // Position labels
            regionLabelsLayer.scaleX = scale;
            regionLabelsLayer.scaleY = scale;

            positionLayerChildren(scale, citiesAndTownsLayer);
        }

        public function positionLayerChildren(scale:Number, layer:MovieClip):void {
            for (var i:int = 0; i < layer.numChildren; i++) {
                var label:MapLabel = layer.getChildAt(i) as MapLabel;
                label.x = label.point.x * scale;
                label.y = label.point.y * scale;
            }
        }

        private function labelRegions():void {
            var regionLabels:Array = [];
            for each (var region:Object in civ.regions) {
                var label:RegionLabel = new RegionLabel(region);
                regionLabels.push(label);
            }

            for each (label in regionLabels)
                regionLabelsLayer.addChild(label);
        }

        private function labelCitiesAndTowns():void {
            var label:IconLabel;
            for each (var town:Town in civ.towns) {
                label = new IconLabel(Icons.townIconFromType(town.townType));
                label.point = new Point(town.cell.point.x, town.cell.point.y);
                label.x = label.point.x;
                label.y = label.point.y;
                citiesAndTownsLayer.addChild(label);
            }

            for each (var city:City in civ.cities) {
                label = new CityLabel(new Icons.City(), city.name);
                label.point = new Point(city.cell.point.x, city.cell.point.y);
                label.x = label.point.x;
                label.y = label.point.y;
                citiesAndTownsLayer.addChild(label);
            }
        }

        public function toggle():void {
            for (var i:int = 0; i < numChildren; i++)
                getChildAt(i).visible = !getChildAt(i).visible;
        }
    }
}