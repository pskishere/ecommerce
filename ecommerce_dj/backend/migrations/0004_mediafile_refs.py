import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('backend', '0003_alter_category_id'),
        ('mediafiles', '0001_initial'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='banner',
            name='image_name',
        ),
        migrations.RemoveField(
            model_name='category',
            name='banner_name',
        ),
        migrations.RemoveField(
            model_name='category',
            name='icon_name',
        ),
        migrations.RemoveField(
            model_name='favorite',
            name='image_name',
        ),
        migrations.RemoveField(
            model_name='history',
            name='image_name',
        ),
        migrations.RemoveField(
            model_name='orderproduct',
            name='image_name',
        ),
        migrations.RemoveField(
            model_name='product',
            name='image_name',
        ),
        migrations.RemoveField(
            model_name='sku',
            name='image_name',
        ),
        migrations.RemoveField(
            model_name='specvalue',
            name='image_name',
        ),
        migrations.RemoveField(
            model_name='subcategory',
            name='icon_name',
        ),
        migrations.RemoveField(
            model_name='productdetail',
            name='detail_images',
        ),
        migrations.RemoveField(
            model_name='productdetail',
            name='images',
        ),
        migrations.RemoveField(
            model_name='review',
            name='images',
        ),
        migrations.AddField(
            model_name='banner',
            name='image',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='banners', to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='category',
            name='banner',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='category_banners', to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='category',
            name='icon',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='category_icons', to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='favorite',
            name='image',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='favorite_images', to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='history',
            name='image',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='history_images', to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='orderproduct',
            name='image',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='product',
            name='image',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='product_images', to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='sku',
            name='image',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='specvalue',
            name='image',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='subcategory',
            name='icon',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='mediafiles.mediafile'),
        ),
        migrations.AlterField(
            model_name='productdetail',
            name='shop_logo',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='shop_logos', to='mediafiles.mediafile'),
        ),
        migrations.AlterField(
            model_name='review',
            name='user_avatar',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='review_avatars', to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='productdetail',
            name='detail_images',
            field=models.ManyToManyField(blank=True, related_name='product_detail_extras', to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='productdetail',
            name='images',
            field=models.ManyToManyField(blank=True, related_name='product_detail_images', to='mediafiles.mediafile'),
        ),
        migrations.AddField(
            model_name='review',
            name='images',
            field=models.ManyToManyField(blank=True, related_name='review_images', to='mediafiles.mediafile'),
        ),
    ]