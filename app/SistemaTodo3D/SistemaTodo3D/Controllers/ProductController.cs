using Infrastructure.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Web.Controllers
{
    public class ProductController : Controller
    {
        private readonly ProductRepository _repository;

        public ProductController(
            ProductRepository repository)
        {
            _repository = repository;
        }
        public IActionResult Index()
        {
            var productos = _repository.ObtenerTodos();

            return View(productos);
        }
    }
}
