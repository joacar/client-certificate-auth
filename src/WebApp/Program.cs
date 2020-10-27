using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

#if USE_KESTREL
using Microsoft.AspNetCore.Server.Kestrel.Https;
#endif

namespace WebApp
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>()
#if USE_KESTREL
                        .ConfigureKestrel(options =>
                        {
                            options.ConfigureHttpsDefaults(https =>
                            {
                                https.ClientCertificateMode = ClientCertificateMode.RequireCertificate;
                                // PartialChain unable to get local issuer certificate
                                https.ClientCertificateValidation = (certificate2, chain, arg3) => true;
                            });
                        })
#endif
                        ;
                });
    }
}
