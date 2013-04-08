package {
	import Box2D.Common.Math.b2Vec2;
	import flash.display.Sprite;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	public class userData extends Sprite {
		var id:int,texture:BitmapData;
		public function userData(id:int, verticesVec:Vector.<b2Vec2>, texture:BitmapData) {
			this.id=id;
			this.texture=texture;
			// I use the matrix so that I can have the center of the shape I'm drawing match the center of the BitmapData image - I "move" the BitmapData projection left by half its width and up by half its height.
			var m:Matrix = new Matrix();
			m.tx=- texture.width*0.5;
			m.ty=- texture.height*0.5;
			// I then draw lines from each vertex to the next, in clockwise order and use the beginBitmapFill() method to add the texture.
			this.graphics.lineStyle(1);
			this.graphics.beginBitmapFill(texture, m, true, true);
			this.graphics.moveTo(verticesVec[0].x*30, verticesVec[0].y*30);
			for (var i:int=1; i<verticesVec.length; i++) {
				this.graphics.lineTo(verticesVec[i].x*30, verticesVec[i].y*30);
			}
			this.graphics.lineTo(verticesVec[0].x*30, verticesVec[0].y*30);
			this.graphics.endFill();
		}
	}
}