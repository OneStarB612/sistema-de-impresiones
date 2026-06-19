using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Infrastructure.Security;
using Web.Models;

namespace Web.Controllers
{
    public class AccountController : Controller
    {


        private readonly Infrastructure.Security.IAuthenticationService _auth;



        public AccountController(

            Infrastructure.Security.IAuthenticationService auth)
        {
            _auth = auth;
        }





        [HttpGet]
        public IActionResult Login()
        {

            return View();
        }






        [HttpPost]
        public async Task<IActionResult>

            Login(LoginVM vm)
        {


            if (!ModelState.IsValid)
                return View(vm);


            var principal = await _auth.AuthenticateAsync( vm.Username, vm.Password);

            if (principal == null)
            {
                ModelState.AddModelError("", "Credenciales incorrectas");

                return View(vm);
            }




            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);



            return RedirectToAction(

                "Index",

                "Home"
            );

        }




        public async Task<IActionResult>

            Logout()
        {


            await HttpContext.SignOutAsync();



            return RedirectToAction(

                "Login");
        }



    }
}
