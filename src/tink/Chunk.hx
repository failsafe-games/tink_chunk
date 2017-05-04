package tink;

import haxe.io.Bytes;
import haxe.io.BytesData;
import tink.chunk.*;

private class EmptyChunk extends ChunkBase implements ChunkObject {
  public function new() { }
    
  public function getLength()
    return 0;
    
  public function slice(from:Int, to:Int):Chunk
    return this;
    
  public function blitTo(target:Bytes, offset:Int):Void {}
    
  public function toString()
    return '';
    
  public function toBytes()
    return EMPTY;
    
  static var EMPTY = Bytes.alloc(0);
}

private class CompoundChunk extends ChunkBase implements ChunkObject {
  var left:Chunk;
  var right:Chunk;
  
  var split:Int;
  var length:Int;
  
  public function getLength()
    return this.length;
    
  public function new(left:Chunk, right:Chunk) {
    //TODO: try balancing here
    this.left = left;
    this.right = right;
    this.split = left.length;
    this.length = split + right.length;
  }
  
  override public function flatten(into:Array<ByteChunk>) {
    (left:ChunkObject).flatten(into);
    (right:ChunkObject).flatten(into);
  }
    
  public function slice(from:Int, to:Int):Chunk 
    return
      left.slice(from, to).concat(right.slice(from - split, to - split));
    
  public function blitTo(target:Bytes, offset:Int):Void {
    left.blitTo(target, offset);
    right.blitTo(target, offset + split);
  }
    
  public function toString() 
    return toBytes().toString();
    
  public function toBytes() {
    var ret = Bytes.alloc(this.length);
    blitTo(ret, 0);
    return ret;
  }
  
}

abstract Chunk(ChunkObject) from ChunkObject to ChunkObject {
  
  public var length(get, never):Int;
    inline function get_length()
      return this.getLength();
      
  public function concat(that:Chunk) 
    return switch [length, that.length] {
      case [0, 0]: EMPTY;
      case [0, _]: that;
      case [_, 0]: this;
      case _: new CompoundChunk(this, that);
    }
    
  public inline function cursor()  
    return this.getCursor();
  
  public inline function iterator()
    return new ChunkIterator(this.getCursor());
      
  public inline function slice(from:Int, to:Int):Chunk 
    return this.slice(from, to);
    
  public inline function blitTo(target:Bytes, offset:Int)
    return this.blitTo(target, offset);
  
  public inline function toHex()
    return this.toBytes().toHex();
    
  @:to public inline function toString()
    return this.toString();
    
  @:to public inline function toBytes()
    return this.toBytes();
    
  static public function join(chunks:Array<Chunk>)
    return switch chunks {
      case null | []: EMPTY;
      case [v]: v;
      case v:
        var ret = v[0] & v[1];
        for (i in 2...v.length)
          ret = ret & v[i];
        ret;
    }

  @:from public static inline function ofBytes(b:Bytes):Chunk 
    return (ByteChunk.of(b) : ChunkObject);
    
  @:from public static inline function ofString(s:String):Chunk 
    return ofBytes(Bytes.ofString(s));
    
  @:op(a & b) static function catChunk(a:Chunk, b:Chunk)
    return a.concat(b);
    
  @:op(a & b) static function rcatString(a:Chunk, b:String)
    return catChunk(a, b);
    
  @:op(a & b) static function lcatString(a:String, b:Chunk)
    return catChunk(a, b);
    
  @:op(a & b) static function lcatBytes(a:Bytes, b:Chunk)
    return catChunk(a, b);
    
  @:op(a & b) static function rcatBytes(a:Chunk, b:Bytes)
    return catChunk(a, b);
    
  static public var EMPTY(default, null):Chunk = ((new EmptyChunk() : ChunkObject) : Chunk);//haxe 3.2.1 ¯\_(ツ)_/¯
}