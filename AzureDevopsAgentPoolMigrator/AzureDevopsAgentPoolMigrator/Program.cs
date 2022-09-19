﻿namespace AzureDevopsAgentPoolMigrator
{
    using System;
    using System.Diagnostics;
    using System.IO;
    using System.Reflection;
    using System.Threading.Tasks;

    public class Program
    {
        private const string azureDevopsUri = "https://dev.azure.com";

        private const string collection = "<collection>";

        private static string project;

        private const string pat = "<PAT token with sufficient privileges, see Readme>";

        private const string logFile = "C:\\temp\\log_migrate_agentpools.txt";

        private static async Task Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Please provide a Team Project");
                return;
            }
            project = args[0];
            var clientManager = new ClientManager();
            clientManager.ConfigureConnectionAndClients(azureDevopsUri, collection, project, pat);

            await MigrateAgentPools(clientManager);
        }

        private static async Task MigrateAgentPools(ClientManager clientManager)
        {
            Console.WriteLine("Start migrating agent pools");

            Log(string.Empty, includeTimestamp: false);

            var migrator = new AgentPoolMigrator(clientManager);
            await migrator.Migrate(collection, project);

            Log("\r\n---------------------------------------------------------------", includeTimestamp: false);

            Console.WriteLine("Done migrating agent pools");
            var logFilePath = Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), logFile);
            Console.WriteLine($"Logfile: {logFilePath}");
        }

        public static void Log(string logMessage, bool includeTimestamp = true)
        {
            using StreamWriter writer = File.AppendText(logFile);
            if (includeTimestamp)
            {
                writer.WriteLine($"[{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff}] - {logMessage}");
            }
            else
            {
                writer.WriteLine(logMessage);
            }
        }
    }
}
