import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../domain/entities/report_image.dart';

Future<ReportImageUpload?> pickReportPhoto() async {
  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (image == null) return null;
  final name = image.name.toLowerCase();
  final mime = ApiConstants.allowedImageMimeTypes.contains(image.mimeType)
      ? image.mimeType
      : name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
              ? 'image/webp'
              : name.endsWith('.jpg') || name.endsWith('.jpeg')
                  ? 'image/jpeg'
                  : null;
  if (mime == null) throw const ApiException(ApiFailure.unsupportedImage);
  if (await image.length() > ApiConstants.reportImageMaxBytes)
    throw const ApiException(ApiFailure.imageTooLarge);
  return ReportImageUpload(
      bytes: await image.readAsBytes(),
      filename: image.name,
      contentType: mime);
}
