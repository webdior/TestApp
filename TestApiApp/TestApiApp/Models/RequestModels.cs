using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web;

namespace TestApiApp.Models
{
    public class RequestModels
    {
        
        [Required (ErrorMessage= "UserId is required.")]
        public string uid { get; set; }
       
        public string xpos { get; set; }
        public string ypos { get; set; }
        public string orientation { get; set; }
        public string type { get; set; }
        public string timestamp { get; set; }
        public string adddata( string user , string pwd,  string Uid, string xpos, string ypos, string orientation, string type, string timestamp)//string id, string xpos, string ypos, string orientation, string type, string timestamp )
        {
            string apiurl = System.Configuration.ConfigurationManager.AppSettings["apiurl"]; 
            ArrayList paramList = new ArrayList();
            Product product = new Product { UserId  = Uid  ,  xpos = xpos, ypos= ypos, orientation = orientation, type = type, timestamp = timestamp }; 
      
            paramList.Add(product);
               
            HttpClient httpClient = new HttpClient();
      
            httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
           
            string authInfo = user + ":" + pwd ;
            authInfo = Convert.ToBase64String( Encoding.Default.GetBytes(authInfo));

            httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", authInfo);

            
            HttpResponseMessage response = httpClient.PostAsJsonAsync(apiurl + "api/Apis/add/", paramList).Result;

            string valuetest = response.Content.ReadAsAsync<string>().Result;
            return valuetest;
        }
    
    }
  
}