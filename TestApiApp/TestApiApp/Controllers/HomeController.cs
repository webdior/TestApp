using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace TestApiApp.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            
            ViewBag.Message = "Modify this template to jump-start your ASP.NET MVC application.";

            return View();
        }

        public ActionResult About()
        {
            ViewBag.Message = "Your app description page.";

            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }
        [HttpPost]

        public JsonResult mongod(string Xpos, string Ypos, string Uid, string Orientation, string Type, Models.RequestModels mrmodel)
        {
            try
            {

                string userid = "dev";
                string password = "123456";
                string timestamp = Convert.ToString(DateTime.Now);
                mrmodel.adddata(userid, password, Uid, Xpos, Ypos, Orientation, Type, timestamp);
              
                return Json(mrmodel);
            }
            catch (HttpException ex)
            {
                throw new HttpException(ex.Message);
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
       

        [HttpGet]
        public ActionResult RequestData()
        {
            //if(sendFlag)
            //{
            //    ViewBag.data = "true";
           return View();
            //}
            //else
            //{
            //    return View("Index");
            //}
        }

        [HttpGet]
        public ActionResult Demo()
        {
            return View();
        }

      

        
    }

}
