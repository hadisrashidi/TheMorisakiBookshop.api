namespace TheMorisakiBookshop.Storage
{
    // Saves uploaded images on disk. The folder is "Uploads:RootPath" from appsettings
    // (a relative path is inside the project folder). Program.cs serves it at /uploads.
    // The caller (ImagesManagementController) has already checked the folder name and the file type.
    public class ImageStorage
    {
        private const string PublicPath = "/uploads";

        public string RootPath { get; }

        public ImageStorage(IConfiguration configuration, IHostEnvironment environment)
        {
            string configuredPath = configuration["Uploads:RootPath"] ?? "uploads";

            if (Path.IsPathRooted(configuredPath))
            {
                RootPath = configuredPath;
            }
            else
            {
                RootPath = Path.Combine(environment.ContentRootPath, configuredPath);
            }

            Directory.CreateDirectory(RootPath);
        }

        // Returns the public path of the saved file, e.g. /uploads/covers/3f2a....jpg
        public async Task<string> SaveAsync(IFormFile file, string folder, CancellationToken cancellationToken)
        {
            // A random name: the uploaded file name is never used, so it cannot overwrite or escape the folder.
            string extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            string fileName = Guid.NewGuid().ToString("N") + extension;

            string folderPath = Path.Combine(RootPath, folder);
            Directory.CreateDirectory(folderPath);

            string filePath = Path.Combine(folderPath, fileName);

            using (FileStream stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream, cancellationToken);
            }

            return PublicPath + "/" + folder + "/" + fileName;
        }
    }
}
