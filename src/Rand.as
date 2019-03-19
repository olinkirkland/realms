package {
    public class Rand {
        private var seed:Number;
        private const max:Number = 1 / int.MAX_VALUE;
        private const min:Number = -max;

        public function Rand(seed:Number = 0) {
            this.seed = seed;
        }

        public function next():Number {
            seed ^= (seed << 21);
            seed ^= (seed >>> 35);
            seed ^= (seed << 4);
            if (seed > 0) return seed * max;
            return seed * min;
        }
    }
}