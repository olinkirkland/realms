package geography {
    import graph.Center;

    import mx.utils.UIDUtil;

    public class Geography {
        private static var _instance:Geography;
        public var features:Object = {};
        public var colors:Object = {};

        public function Geography() {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;

            // Setup
            colors[Feature.OCEAN] = 0x387089;
            colors[Feature.LAND] = 0x387089;
            colors[Feature.LAKE] = 0x387089;
        }

        public static function getInstance():Geography {
            if (!_instance)
                new Geography();
            return _instance;
        }

        public function reset():void {
            features = {};
        }

        public function registerFeature(type:String):String {
            var id:String = UIDUtil.createUID();

            features[id] = {id: id, type: type, centers: new Vector.<Center>(), color: colors[type]};
            if (type == Feature.OCEAN)
                features[id].color = 0x4890B1;

            return id;
        }

        public function deleteFeature(id:String):void {
            delete features[id];
        }

        public function addCenterToFeature(center:Center, feature:String):void {
            center.features.push(feature);
            features[feature].centers.push(center);
        }

        public function removeCenterFromFeature(center:Center, feature:String):void {
            center.features.removeAt(center.features.indexOf(feature));
            features[feature].centers.removeAt(features[feature].centers.indexOf(center));
        }

        public function getFeature(id:String):Object {
            return features[id];
        }

        public function getFeaturesByType(type:String):Object {
            var obj:Object = {};
            for (var key:String in features) {
                if (features[key].type == type) {
                    obj[key] = features[key];
                }
            }

            return obj;
        }
    }
}