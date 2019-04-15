package labels {
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class LandLabel extends MapLabel {
        public function LandLabel(land:Object) {
            super();

            var fontSize:int = 10;
            if (land.analysis["tinyIsland"])
                fontSize = 12;
            if (land.analysis["smallIsland"])
                fontSize = 16;
            if (land.analysis["largeIsland"])
                fontSize = 24;
            if (land.analysis["continent"])
                fontSize = 36;

            var format:TextFormat = new TextFormat(Fonts.fancy, fontSize, 0x000000);
            var txt:TextField = new TextField();
            txt.embedFonts = true;
            txt.defaultTextFormat = format;
            txt.selectable = false;
            txt.alpha = .6;
            txt.text = land.name;
            txt.autoSize = TextFieldAutoSize.LEFT;
            txt.width = txt.textWidth;
            addChild(txt);

            txt.x = -txt.width / 2;
            txt.y = -txt.height / 2;
        }
    }
}
