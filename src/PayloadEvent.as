package {
    import flash.events.Event;

    public class PayloadEvent extends Event {
        public var payload:Object;

        public function PayloadEvent(type:String, payload:Object, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type, bubbles, cancelable);
            this.payload = payload;
        }
    }
}