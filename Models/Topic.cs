using System.ComponentModel.DataAnnotations;

public class ChuDe
{
    public int Id { get; set; }

    [Required]
    [Display(Name = "Tên chủ đề")]
    public string TenChuDe { get; set; }
    public bool DaDoc { get; set; }
}
