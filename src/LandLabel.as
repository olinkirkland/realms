package {
    import flash.display.MovieClip;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    import generation.Enumerators.LandType;

    public class LandLabel extends MovieClip {
        public function LandLabel(land:Object) {
            var fontSize:int;
            switch (land.landType) {
                case LandType.tinyIsland:
                    fontSize = 12;
                    break;
                case LandType.smallIsland:
                    fontSize = 18;
                    break;
                case LandType.largeIsland:
                    fontSize = 24;
                    break;
                case LandType.continent:
                    fontSize = 32;
                    break;
                default:
                    break;
            }

            var format:TextFormat = new TextFormat(Fonts.elaborateTitle, fontSize, 0x000000);
            var txt:TextField = new TextField();
            txt.embedFonts = true;
            txt.defaultTextFormat = format;
            txt.selectable = false;
            txt.alpha = .6;
            txt.text = land.name;
            txt.autoSize = TextFieldAutoSize.LEFT;
            txt.width = txt.textWidth;
            addChild(txt);
            txt.borderColor = 0xff0000;
            txt.border = true;

            txt.x = -txt.width / 2;
        }
    }
}
