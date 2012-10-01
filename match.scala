import scala.io._
import scala.util.parsing.json._
import scala.collection._

object SortableChallenge {
  val products = mutable.HashMap.empty[String,mutable.HashMap[String,String]]
  val matches = mutable.HashMap.empty[String,mutable.HashSet[String]]

  def main(args: Array[String]) {
    scala.io.Source.fromFile("products.txt").getLines().foreach { line =>
      val json: Option[Any] = JSON.parseFull(line)
      val map: Map[String,Any] = json.get.asInstanceOf[Map[String, Any]]
      val manufacturer: String = map.get("manufacturer").get.asInstanceOf[String]
      val model: String = map.get("model").get.asInstanceOf[String]
      val product_name: String = map.get("product_name").get.asInstanceOf[String]
      if(!products.contains(manufacturer)) products(manufacturer) = mutable.HashMap.empty[String,String] 
      products(manufacturer)(model) = product_name
    }
  }
}
