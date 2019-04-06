package geography {
    import graph.Cell;

    import mx.utils.UIDUtil;

    public class Settlements {
        private static var _instance:Settlements;

        // Generation
        public var settlementsById:Object = {};
        public var settlementsByCell:Object = {};

        public function Settlements() {
            if (_instance)
                throw new Error("Singleton; Use getInstance() instead");
            _instance = this;
        }

        public static function getInstance():Settlements {
            if (!_instance)
                new Settlements();
            return _instance;
        }

        public function get settlements():Object {
            return settlementsById;
        }

        public function reset():void {
            settlementsById = {};
            settlementsByCell = {};
        }

        public function registerSettlement(cell:Cell):String {
            var id:String = UIDUtil.createUID();
            var settlement:Settlement = new Settlement(cell, id);
            cell.settlement = settlement;

            settlementsById[id] = settlement;
            settlementsByCell[cell] = settlement;

            return id;
        }
    }
}