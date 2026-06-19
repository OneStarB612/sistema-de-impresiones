using Infrastructure.Data;
using Infrastructure.Repositories;
using Microsoft.AspNetCore.Authentication.Cookies;
using Infrastructure.Security;
using Microsoft.AspNetCore.Authorization;


namespace SistemaTodo3D
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            builder.Services.AddAuthentication(
                CookieAuthenticationDefaults.AuthenticationScheme)
                .AddCookie(options =>
                {

                    options.LoginPath = "/Account/Login";

                    options.AccessDeniedPath = "/Account/Denied";


                    options.ExpireTimeSpan =
                    TimeSpan.FromHours(8);


                });

            builder.Services.AddAuthorization();
            builder.Services.AddScoped<IAuthenticationService,AuthenticationService>();

            builder.Services.AddSingleton<IAuthorizationHandler,PermissionHandler>();

            builder.Services.AddScoped<SqlConnectionFactory>();
            builder.Services.AddScoped<UserRepository>();

            builder.Services.AddScoped<ProductRepository>();

            builder.Services.AddAuthorization(options =>
            {
                options.AddPolicy(
                "Create",
                policy =>
                policy.Requirements.Add(
                new PermissionRequirement(
                "create"
                )));
                options.AddPolicy(
                "Consult",
                policy =>
                policy.Requirements.Add(

                new PermissionRequirement(
                "consult"
                )));
            });

            // Add services to the container.
            builder.Services.AddControllersWithViews();


            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (!app.Environment.IsDevelopment())
            {
                app.UseExceptionHandler("/Home/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseStaticFiles();

            app.UseRouting();

            app.UseAuthentication();


            app.UseAuthorization();

            app.MapControllerRoute(
                name: "default",
                pattern: "{controller=Home}/{action=Index}/{id?}");

            app.Run();
        }
    }
}
