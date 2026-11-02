namespace PdksApp.Models;

public record SubscribePlanDto(
    int CompanyId,
    int PlanType, // 1: Monthly (200 TL), 2: Yearly (2000 TL)
    string CardHolderName,
    string CardNumber,
    string ExpireMonth,
    string ExpireYear,
    string Cvc
);
