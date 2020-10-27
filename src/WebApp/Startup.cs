using Microsoft.AspNetCore.Authentication.Certificate;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;
using System.IO;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;

namespace WebApp
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseRouting();

            app.UseCertificateForwarding();
            app.UseAuthentication();
            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.Map("/hello", async context =>
                {
                    await context.Response.WriteAsync($"Hello, {context.User.Identity.Name}{Environment.NewLine}").ConfigureAwait(false);
                    foreach (var claim in context.User.Claims)
                    {
                        await context.Response.WriteAsync($"Claim {claim.Type} = {claim.Value}{Environment.NewLine}").ConfigureAwait(false);
                    }
                }).RequireAuthorization();
            });
        }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddCertificateForwarding(options =>
            {
                options.CertificateHeader = "X-Forwarded-Client-Cert";
                options.HeaderConverter = headerValue =>
                {
                    var raw = Uri.UnescapeDataString(headerValue);
                    if (raw.StartsWith("-----", StringComparison.Ordinal)) raw = StripDescriptor();

                    var bytes = Convert.FromBase64String(raw);
                    var cert = new X509Certificate2(bytes);

                    string StripDescriptor()
                    {
                        var sb = new StringBuilder();
                        using var sr = new StringReader(raw);
                        string? line;
                        while ((line = sr.ReadLine()) != null)
                        {
                            if (line.StartsWith("-----", StringComparison.Ordinal)) continue;

                            sb.Append(line);
                        }

                        return sb.ToString();
                    }

                    return cert;
                };
            });

            services.AddAuthentication(CertificateAuthenticationDefaults.AuthenticationScheme)
                .AddCertificate(options =>
                {
#if DEBUG
                    options.AllowedCertificateTypes = CertificateTypes.All;
                    options.RevocationMode = X509RevocationMode.NoCheck;
#endif
                    options.Events = new CertificateAuthenticationEvents
                    {
                        OnAuthenticationFailed = context => Task.CompletedTask,
                        OnCertificateValidated = context => Task.CompletedTask,

                    };
                });

            services.AddAuthorization();
        }
    }
}