using System.ComponentModel.DataAnnotations;

namespace Web.Views.ViewModels
{


public class LoginVM
{

    [Required]
    public string Username { get; set; }



    [Required]

    public string Password { get; set; }

}
}
